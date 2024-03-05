=begin
  Layoutシステム/Windowを使った描画対象
=end
class Itefu::Layout::Control::Window < Itefu::Layout::Control::Decorator
  include Itefu::Layout::Control::RenderTarget
  attr_reader :window
  attr_bindable :opacity
  attr_bindable :openness
  attr_bindable :viewport
  attr_bindable :contents_opacity

  def buffer; window.contents; end
  def z; window.z; end

  # 子コントロールの描画位置の補正
  def drawing_offset_x
    if @window
      super - @window.ox
    else
      super
    end
  end

  # 子コントロールの描画位置の補正
  def drawing_offset_y
    if @window
      super - @window.oy
    else
      super
    end
  end
  
  def initialize(parent, buffer_w = 0, buffer_h = 0, z = nil)
    @window = Itefu::Rgss3::Window.new(0, 0, buffer_w, buffer_h)
    @window.z = z || z_index
    create_buffer
    super(parent)
    self.viewport = root.view.viewport if root.view.viewport
  end

  # Viewportをデフォルト状態=Viewの設定されたものに戻す
  def reset_viewport
    self.viewport = root.view.viewport
    @using_custom_viewport = false
  end
  
  alias :viewport_org= :viewport=
  def viewport=(vp)
    # 独自のViewportを設定したことを覚えておく
    @using_custom_viewport = true unless vp.equal?(root.view.viewport)
    self.viewport_org = vp
  end
  
  # Viewに設定されているviewportが変更された
  def notify_of_viewport
    super
    self.viewport = root.view.viewport unless @using_custom_viewport
  end

  # 終了処理
  def impl_finalize
    super
    @window = @window.swap(nil)
  end

  def disarrange(control = nil)
    parent.disarrange(control || self)
  end

  # 更新
  def impl_update
    super
    @window.update
    @shown = nil
  end

  # 描画  
  def impl_draw
    @window.visible = shown?
    super
  end

  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :viewport
      @window.viewport = viewport
    when :openness
      @window.openness = openness
    when :opacity
      if contents_opacity
        @window.opacity = opacity
      else
        @window.opacity = @window.contents_opacity = opacity
      end
    when :contents_opacity
      @window.contents_opacity = contents_opacity
    end if @window && @window.disposed?.!
    super
  end
  
  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :viewport, :openness, :opacity, :contents_opacity
      true
    else
      super
    end
  end

  # 再描画不要の条件
  def stable_in_appearance?(name)
    case name
    when :visibility, :viewport, :openness, :opacity, :contents_opacity
      true
    else
      super
    end
  end

  def arrange(final_x, final_y, final_w, final_h)
    if @window
      @window.x      = final_x if @window.x      != final_x
      @window.y      = final_y if @window.y      != final_y
      @window.width  = final_w if @window.width  != final_w
      @window.height = final_h if @window.height != final_h
      super(@window.contents_x(final_x) - @window.ox, @window.contents_y(final_y) - @window.oy, @window.contents_width, @window.contents_height)
      @screen_x = @window.contents_x(final_x)
      @screen_y = @window.contents_y(final_y)
    else
      super
    end
  end
  
  # RGSS3で用意されているウィンドウのカーソル矩形を設定する
  def cursor_rect=(rect)
    return unless @window && @window.disposed?.!

    case rect 
    when Rect, ::Rect
      x = rect.x + @window.ox
      y = rect.y + @window.oy
      reset_cursor_rect(x, y, x + rect.width, y + rect.height)
    when Box
      ox = @window.ox - self.screen_x
      oy = @window.oy - self.screen_y
      reset_cursor_rect(rect.left + ox, rect.top + oy, rect.right + ox, rect.bottom + oy)
    when Itefu::Layout::Control::Base
      left   = rect.screen_x - self.screen_x + @window.ox
      top    = rect.screen_y - self.screen_y + @window.oy
      reset_cursor_rect(
        left, top,
        left + rect.actual_width,
        top + rect.actual_height
      )
    else
      @window.cursor_rect.empty
    end
  end

  #
  def cursor_rect
    return unless @window && @window.disposed?.!
    @window.cursor_rect
  end
 
  # ウィンドウからはみださない用にウィンドウのカーソル矩形を設定する 
  def reset_cursor_rect(left, top, right, bottom)
    return unless @window && @window.disposed?.!
    max_w = @window.contents_width  - 1
    max_h = @window.contents_height - 1
    left   = Utility::Math.clamp(0, max_w, left)
    top    = Utility::Math.clamp(0, max_h, top)
    right  = Utility::Math.clamp(0, max_w, right)
    bottom = Utility::Math.clamp(0, max_h, bottom)
    w = right - left
    h = bottom - top
    if w > 0 && h > 0
      @window.cursor_rect.set(left, top, w, h)
    else
      @window.cursor_rect.empty
    end
  end


private

  # 計測
  def impl_measure(available_width, available_height)
    if @window
      # 子のサイズを計算する際は、ウィンドウ枠の分を控除する（追加分のマージンと考える）
      @desired_width = @window.contents_width(@desired_width)
      @desired_height = @window.contents_height(@desired_height)
      super(@window.contents_width(available_width), @window.contents_height(available_height))
      # 外から見たこのコントロール自体のサイズは、ウィンドウ枠分を加味したものにする
      @desired_width  = @window.window_width(@desired_width)
      @desired_height = @window.window_height(@desired_height)
    else
      super
    end
  end
  
  # 整列
  def actualize_position_and_size(final_x, final_y, final_w, final_h)
    super
    if @window
      create_buffer
    end
  end

  # 描画用のBitmapを生成する
  # @param [ContentsCreation] mode Bitmapを生成する条件
  def create_buffer(mode = nil)
    cw = @window.contents_width
    ch = @window.contents_height

    case mode || contents_creation
    when ContentsCreation::IF_RESIZED, nil
      if @window.contents.empty? || (cw != @window.contents.width) || (ch != @window.contents.height)
        create_contents(cw, ch)
      end
    when ContentsCreation::IF_EMPTY
      if @window.contents.empty?
        create_contents(cw, ch)
      end
    when ContentsCreation::IF_LARGE
      if @window.contents.empty? || (cw > @window.contents.width) || (ch > @window.contents.height)
        create_contents(cw, ch)
      end
    when ContentsCreation::ALWAYS
      create_contents(cw, ch)
    end
  end
  
  # Windowのcontentsを生成する
  # @param [Fixnum] cw 生成するcontentsの横幅
  # @param [Fixnum] ch 生成するcontentsの高さ
  def create_contents(cw, ch)
    @window.create_contents(cw, ch)
    be_corrupted
  end

end
