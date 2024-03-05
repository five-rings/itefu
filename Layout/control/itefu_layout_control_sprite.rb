=begin
  Layoutシステム/Spriteを使った描画対象
=end
module Itefu::Layout::Control::SpriteTarget
  include Itefu::Layout::Control::RenderTarget
  extend Itefu::Layout::Control::Bindable::Extension
  attr_reader :sprite
  attr_bindable :anchor_x, :anchor_y    # [Numeric] 回転の中心になるアンカーポイント, 小数だとサイズの割合になる
  attr_bindable :opacity, :color, :tone, :blend_type, :mirror
  attr_bindable :viewport

  def buffer; sprite.bitmap; end
  def z; sprite.z; end
  
  Size = Itefu::Layout::Definition::Size

  def initialize(parent, buffer_w = 0, buffer_h = 0)
    super(parent)
    initialize_sprite_variables(buffer_w, buffer_h)
  end

  def initialize_sprite_variables(buffer_w = 0, buffer_h = 0)
    @sprite = Itefu::Rgss3::Sprite.new
    @sprite.z = z_index
    create_buffer(buffer_w, buffer_h)
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

  # extendされたときに変数を初期化する
  def self.extended(object)
    unless object.sprite
      object.initialize_sprite_variables
    end
  end
  
  # 終了処理
  def impl_finalize
    super
    @sprite = @sprite.swap(nil)
  end

  # 更新
  def impl_update
    super
    @sprite.update
    @shown = nil
  end

  # 描画  
  def impl_draw
    @sprite.visible = shown?
    super
  end
  
  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :viewport
      @sprite.viewport = viewport
    when :anchor_x
      @sprite.ox = Size.to_actual_value(anchor_x, actual_width) if actual_width
    when :anchor_y
      @sprite.oy = Size.to_actual_value(anchor_y, actual_height) if actual_height
    when :opacity
      @sprite.opacity = opacity
    when :color
      @sprite.color = color
    when :tone
      @sprite.tone = tone
    when :blend_type
      @sprite.blend_type = blend_type
    when :mirror
      @sprite.mirror = mirror
    end if @sprite && @sprite.disposed?.!
    super
  end
  
  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :viewport, :anchor_x, :anchor_y,
         :opacity, :color, :tone, :blend_type, :mirror
      true
    else
      super
    end
  end

  # 再描画不要の条件
  def stable_in_appearance?(name)
    case name
    when :visibility, :viewport, :anchor_x, :anchor_y,
         :opacity, :color, :tone, :blend_type, :mirror
      true
    else
      super
    end
  end

  def arrange(final_x, final_y, final_w, final_h)
    super
    @sprite.x = final_x + @sprite.ox
    @sprite.y = final_y + @sprite.oy
  end


private

  # 整列
  def actualize_position_and_size(final_x, final_y, final_w, final_h)
    old_width = actual_width
    old_height = actual_height
    super
    if actual_width != old_width || actual_height != old_height
      be_corrupted
    end
    create_buffer(actual_width, actual_height)

    if (ax = anchor_x)
      @sprite.ox = Size.to_actual_value(ax, actual_width)
    end
    if (ay = anchor_y)
      @sprite.oy = Size.to_actual_value(ay, actual_height)
    end
  end

  # 描画用のバッファを作成する
  # @param [Fixnum] w 生成するバッファの横幅
  # @param [Fixnum] h 生成するバッファの高さ
  def create_buffer(w, h)
    return unless w > 0 && h > 0
    
    case contents_creation
    when ContentsCreation::IF_EMPTY, nil
      if @sprite.bitmap.nil?
        create_bitmap(w, h)
      end
    when ContentsCreation::IF_LARGE
      if @sprite.bitmap.nil? || (w > @sprite.bitmap.width) || (h > @sprite.bitmap.height)
        create_bitmap(w, h)
      end
    when ContentsCreation::IF_RESIZED
      if @sprite.bitmap.nil? || (w != @sprite.bitmap.width) || (h != @sprite.bitmap.height)
        create_bitmap(w, h)
      end
    when ContentsCreation::ALWAYS
      create_bitmap(w, h)
    end
  end
  
  # 描画用のBitmapを作成する
  # @param [Fixnum] w 生成するbitmapの横幅
  # @param [Fixnum] h 生成するbitmapの高さ
  def create_bitmap(w, h)
    Itefu::Rgss3::Bitmap.new(w, h).auto_release {|bitmap|
      @sprite.bitmap = bitmap
    }
    be_corrupted
  end
end

# コントロールとして追加する用
class Itefu::Layout::Control::Sprite < Itefu::Layout::Control::Decorator
  include Itefu::Layout::Control::SpriteTarget
end

