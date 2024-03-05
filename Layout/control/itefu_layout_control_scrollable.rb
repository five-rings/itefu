=begin
  Layoutシステム/mixしたコントロールをスクロール可能にする。
  @note include する場合は、self.extended を参考に、その他に必要なモジュールも合わせてincludeすること
=end
module Itefu::Layout::Control::Scrollable
  extend Itefu::Layout::Control::Bindable::Extension
  include Itefu::Layout::Definition
  attr_bindable :scroll_x     # [FixNum] スクロール位置
  attr_bindable :scroll_y     # [FixNum] スクロール位置
  # [Fixnum] scroll_x,y の最大値
  attr_bindable :scroll_x_max, :scroll_y_max
  # [Fixnum] scroll_x,y の最大値
  attr_bindable :scroll_x_min, :scroll_y_min
  # [Orientation] 一方向にだけスクロールする場合の方向
  attr_bindable :scroll_direction
  # [Fixnum] 一方向にだけスクロールする場合のスクロール量の補正
  attr_bindable :scroll_scale

  DEFAULT_SCROLL_SCALE = 1
  
  module Option
    # カーソル位置に自動でスクロールする
    module CursorScroller; end
    # コントロールの（はみ出し多分を含む）内容の範囲でスクロールできるようにする
    module ControlViewer; end
    # 連続でスクロールをしたときまとめて処理する
    module LazyScrolling; end
  end

  # Option にあるモジュールをmix-inする
  # @note *args には Optionのモジュールの名前をsymbolで与える
  def self.option(*args)
    OptionWrapper.instance_variable_set(:@args, args)
    OptionWrapper
  end
  
  # Optionにあるモジュールをmix-inするためのラッパー
  # @note @args にmix-inしたいモジュールの配列を設定してからmix-inする
  module OptionWrapper
    def self.extend_object(object)
      object.extend Itefu::Layout::Control::Scrollable
      @args.each do |klass_symbol|
        klass = Option.const_get(klass_symbol)
        object.extend klass if klass
      end
      @args = nil
      # super # ただのラッパーなのでこのモジュールは追加しなくてよい
    end
  end

  def self.extended(object)
    # 子コントロールの配置・描画用のモジュールをmix-inする
    case object
    when CustomScroll
      # do nothing
    when Itefu::Layout::Control::Window
      object.extend Window
    when Itefu::Layout::Control::SpriteTarget
      object.extend Sprite
    when Itefu::Layout::Control::Decorator,
         Itefu::Layout::Control::Composite
      object.extend Container
    when Itefu::Layout::Control::Drawable
      object.extend Drawable
    else
      ITEFU_DEBUG_OUTPUT_WARNING "Scrollable is mixed-in to #{object.class}.#{object.name}, but no scroll feature is provided."
    end
  end
 
  alias :scroll_x_org :scroll_x 
  # @return [Fixnum] min-maxの範囲にクリッピングした値を返す
  def scroll_x
    Utility::Math.clamp_with_nil(self.scroll_x_min, self.scroll_x_max, self.scroll_x_org)
  end
  
  alias :scroll_y_org :scroll_y
  # @return [Fixnum] min-maxの範囲にクリッピングした値を返す
  def scroll_y
    Utility::Math.clamp_with_nil(self.scroll_y_min, self.scroll_y_max, self.scroll_y_org)
  end
  
  alias :scroll_x_org= :scroll_x=
  # min-maxの範囲にクリッピングした値を設定する
  def scroll_x=(value)
    self.scroll_x_org = Utility::Math.clamp_with_nil(self.scroll_x_min, self.scroll_x_max, value)
  end
  
  alias :scroll_y_org= :scroll_y=
  # min-maxの範囲にクリッピングした値を設定する
  def scroll_y=(value)
    self.scroll_y_org = Utility::Math.clamp_with_nil(self.scroll_y_min, self.scroll_y_max, value)
  end

  # scroll_directionの方向にスクロールする
  def scroll(value)
    return if value == 0
    case scroll_direction 
    when Orientation::VERTICAL
      self.scroll_y = (self.scroll_y || 0) + value * (self.scroll_scale || DEFAULT_SCROLL_SCALE)
    when Orientation::HORIZONTAL
      self.scroll_x = (self.scroll_x || 0) + value * (self.scroll_scale || DEFAULT_SCROLL_SCALE)
    end
  end
 
  # スクロールに合わせて独自処理を実装する
  module CustomScroll
    include Itefu::Layout::Control::Scrollable
    attr_accessor :custom_scroll
    
    def scroll(value)
      if custom_scroll
        # custom_scrollが設定されている場合valueの変更や元クラスを呼ばないようにできる
        value = custom_scroll.call(self, value)
      end
      super if value
    end
  end

  # 描画内容をスクロールする
  module Drawable
    # スクロール分ずらす
    def drwaing_position_x
      super - (self.scroll_x || 0)
    end
    
    # スクロール分ずらす
    def drawing_position_y
      super - (self.scroll_y || 0)
    end
  end
  
  # Windowの中身をスクロールする
  module Window
    # Windowのスクロール機能に任せる
    def binding_value_changed(name, old_value)
      case name
      when :scroll_x
        @window.ox = self.scroll_x
      when :scroll_y
        @window.oy = self.scroll_y
      end if @window
      super
    end

    # 描画済みの内容をスクロールするだけなので再描画は不要
    def stable_in_appearance?(name)
      case name
      when :scroll_x, :scroll_y
        true
      else
        super
      end
    end
  end

  # Spriteの中身をスクロールする
  module Sprite
    # arrangeでSpriteの位置を決めるので、ここではスクロール分ずらさない
    def arrange(final_x, final_y, final_w, final_h)
      super
      # コントロールそのものの位置も動いてしまうので元に戻す
      @screen_x = final_x
      @screen_y = final_y
    end

    # スクロール分ずらす
    def impl_arrange(final_x, final_y, final_w, final_h)
      super(final_x - (self.scroll_x || 0), final_y - (self.scroll_y || 0), final_w, final_h)
    end
    
    # スクロール分ずらす
    def actualize_position_and_size(final_x, final_y, final_w, final_h)
      super(final_x - (self.scroll_x || 0), final_y - (self.scroll_y || 0), final_w, final_h)
    end
  end

  # 子コントロールをスクロールする
  module Container
    # スクロール分だけずらして配置する
    def arrange(final_x, final_y, final_w, final_h)
      super(final_x - (self.scroll_x || 0), final_y - (self.scroll_y || 0), final_w, final_h)
      # 親コントロールの位置も動いてしまうので元に戻す
      @screen_x = final_x
      @screen_y = final_y
    end
  end
  

  # --------------------------------------------------
  # Options
  
  # カーソル位置に自動でスクロールする
  module Option::CursorScroller
    def self.extended(object)
      ITEFU_DEBUG_ASSERT(Itefu::Layout::Control::Selector === object)
    end
    
    # content(paddingを抜いた領域)の外にはみ出したコントロールが画面内に入るようにスクロールする
    def scroll_to_xw(x, w)
      return unless x && w
      rx = x - self.content_left
      if rx < 0
        rx
      else
        rw = rx + w - self.content_width
        if rw > 0
          rw
        end
      end
    end
    
    # content(paddingを抜いた領域)の外にはみ出したコントロールが画面内に入るようにスクロールする
    def scroll_to_yh(y, h)
      return unless y && h
      ry = y - self.content_top
      if ry < 0
        ry
      else
        rh = ry + h - self.content_height
        if rh > 0
          rh
        end
      end
    end

    # カーソルの移動があった場合は、カーソルの合ったコントロールにあわせて、自動的にスクロールする
    def on_active_effect(index)
      scroll_to_child(index)
      super
    end
    
    def scroll_to_child(index)
      if child = child_at(index)
        # marginは省いたサイズにカーソルを合わせる
        # marginはコントロールの配置の調整に使われ、カーソルはコントロールに対して設定されるため
        sx = scroll_to_xw(child.screen_x, child.actual_width)
        self.scroll_x = (self.scroll_x || 0) + sx if sx
        sy = scroll_to_yh(child.screen_y, child.actual_height)
        self.scroll_y = (self.scroll_y || 0 ) + sy if sy
      end
    end

    def disarrange(control = nil)
      parent.disarrange(control || self)
    end
  end

  # コントロールの（はみ出し多分を含む）内容の範囲でスクロールできるようにする
  module Option::ControlViewer
    def arrange(final_x, final_y, final_w, final_h)
      super
      dw = inner_width - content_width
      self.scroll_x_max = Itefu::Utility::Math.max(0, dw)
      self.scroll_x_min = 0

      dh = inner_height - content_height
      self.scroll_y_max = Itefu::Utility::Math.max(0, dh)
      self.scroll_y_min = 0
    end
  end

  # 連続スクロールをまとめて処理する
  module Option::LazyScrolling
    def self.extended(object)
      object.initialize_lazy_scrolling
    end

    def initialize(*args)
      initialize_lazy_scrolling
      super
    end

    def initialize_lazy_scrolling
      @value_to_scroll = 0
    end

    def scroll(value)
      if value != 0
        @value_to_scroll += value
      else
        super(@value_to_scroll)
        @value_to_scroll = 0
      end
    end
  end

end
