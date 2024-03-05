=begin
  Layoutシステム/UIコントロールの基底クラス
=end
class Itefu::Layout::Control::Base
  include Itefu::Layout::Definition
  include Itefu::Layout::Control
  include Itefu::Layout::Control::DSL
  include Itefu::Layout::Control::Bindable
  include Itefu::Layout::Control::Callback

  attr_bindable :name             # [Symbol] コントロールの識別名
  attr_bindable :width            # [Numeric] コントロールの横幅, 整数ならその値, 少数なら最大値からの割合, 負の値なだ最大値から引いた数になる
  attr_bindable :height           # [Numeric] コントロールの高さ, 整数ならその値, 少数なら最大値からの割合, 負の値なだ最大値から引いた数になる
  attr_bindable :margin           # [Box] コントロールの周囲の空白
  attr_bindable :padding          # [Box] コントロールの内側の空白
  attr_bindable :visibility       # [Visibility] コントロールの表示設定
  attr_bindable :max_width        # [Numeric] widthの最大値
  attr_bindable :max_height       # [Numeric] heightの最大値
  attr_bindable :min_width        # [Numeric] widthの最小価
  attr_bindable :min_height       # [Numeric] heightの最小価

  attr_reader   :parent           # [Control::Base] 親コントロール
  attr_reader   :desired_width    # [Fixnum] 希望サイズ(measureで自動計算される)
  attr_reader   :desired_height   # [Fixnum] 希望サイズ(measureで自動計算される)
  attr_reader   :actual_width     # [Fixnum] 表示サイズ(arrangeで自動計算される)
  attr_reader   :actual_height    # [Fixnum] 表示サイズ(arrangeで自動計算される)
  attr_reader   :screen_x         # [Fixnum] 要素のスクリーン座標(arrangeで自動計算される)
  attr_reader   :screen_y         # [Fixnum] 要素のスクリーン座標(arrangeで自動計算される)

  def dead?; @dead; end           # [Boolean] コントロールが破棄済みか
  def alive?; dead?.!; end        # [Boolean] コントロールが生存しているか

  # @return [Control::Root] ルートコントロールを返す
  def root; @root || parent && (@root = parent.root); end
  
  # @return [Control::RenderTarget] 描画対象を返す
  def render_target; @render_target || parent && (@render_target = parent.render_target); end

  # @return [Boolean] レイアウト構築時に場所を占有するか
  def takes_space?; Visibility.takes_space?(visibility); end
  # @return [Boolean] 表示されるか
  def visible?; Visibility.visible?(visibility); end
  
  # padding を抜いた 描画領域
  def content_width;          actual_width - padding.width;               end   # [Fixnum] 内容を描画できる範囲の横幅
  def content_height;         actual_height - padding.height;             end   # [Fixnum] 内容を描画できる範囲の高さ
  def desired_content_width;  desired_width - padding.width;              end   # [Fixnum] 希望する描画範囲の横幅
  def desired_content_height; desired_height - padding.height;            end   # [Fixnum] 希望する描画範囲の高さ
  def content_left;           screen_x + padding.left;                    end   # [Fixnum] 描画できる範囲の左スクリーン座標
  def content_right;          screen_x + actual_width - padding.right;    end   # [Fixnum] 描画できる範囲の右スクリーン座標
  def content_top;            screen_y + padding.top;                     end   # [Fixnum] 描画できる範囲の上スクリーン座標
  def content_bottom;         screen_y + actual_height - padding.bottom;  end   # [Fixnum] 描画できる範囲の下スクリーン座標

  # marginを除いたコントロールの領域（左上)までのオフセット
  def offset_from_left;       margin.left; end
  def offset_from_right;      margin.right + desired_width; end
  def offset_from_top;        margin.top; end
  def offset_from_bottom;     margin.bottom + desired_height; end

  # margin を含めた 占有領域  
  def full_width;             actual_width + margin.width;                end   # [Fixnum] 周囲の余白をあわせたコントロールの横幅
  def full_height;            actual_height + margin.height;              end   # [Fixnum] 周囲の余白をあわせたコントロールの高さ
  def desired_full_width;     desired_width + margin.width;               end   # [Fixnum] 周囲の余白をあわせた希望する横幅
  def desired_full_height;    desired_height + margin.height;             end   # [Fixnum] 周囲の余白をあわせた希望する高さ

  # 表示内容のサイズ
  def inner_width; content_width; end
  def inner_height; content_height; end

  def initialize(parent)
    super
    @parent = parent
    self.width = Size::AUTO
    self.height = Size::AUTO
    self.margin = Box::ZERO
    self.padding = Box::ZERO
    self.visibility = Visibility::VISIBLE
  end
  
  # コントロール破棄時に呼ぶ
  def finalize
    if alive?
      execute_callback(:finalize)
      @dead = true
      impl_finalize
      release_all_binding_objects
      execute_callback(:finalized)
    end
  end

  # 毎フレーム呼ぶ更新処理
  def update
    if alive?
      execute_callback(:update)
      impl_update
      execute_callback(:updated)
    end
  end

  # 毎フレーム呼ぶ描画処理
  def draw
    if alive? && visible?
      execute_callback(:draw)
      impl_draw
      execute_callback(:drawn)
    end
  end

  # コントロールのサイズを計測する
  # @param [Fixnum] available_width 利用可能な横幅
  # @param [Fixnum] available_height 利用可能な高さ
  def measure(available_width, available_height)
    # 現時点でのサイズを計算しておく
    actualize_desired_size(available_width, available_height)
    adjust_desired_size_to_be_in_min_max(available_width, available_height)
    # 計測
    execute_callback(:measure, available_width, available_height)
    impl_measure(available_width, available_height)
    # 計測中に変わる可能性があるので再度
    adjust_desired_size_to_be_in_min_max(available_width, available_height)
    execute_callback(:measured, available_width, available_height)
  end

  # コントロールの位置と大きさを決定する
  # @param [Fixnum] final_x コントロールのスクリーン横座標
  # @param [Fixnum] final_y コントロールのスクリーン縦座標
  # @param [Fixnum] final_w コントロールの横幅
  # @param [Fixnum] final_w コントロールの高さ
  def arrange(final_x, final_y, final_w, final_h)
    # サイズを計算しておく
    actualize_position_and_size(final_x, final_y, final_w, final_h)
    # 計測
    execute_callback(:arrange, final_x, final_y, final_w, final_h)
    impl_arrange(final_x, final_y, final_w, final_h)
    @disarranged = false if @disarranged
    execute_callback(:arranged, final_x, final_y, final_w, final_h)
  end

  # @return [Control::Base] 子コントロールを生成して返す
  # @param [Class] klass 生成するコントロールの型
  # @param [Array] args 生成時に渡す任意の引数
  def create_child_control(klass, *args)
    klass.new(self, *args)
  end

  # attr_bindableで定義した属性が変更されたときに呼ばれる
  # @param [Symbol] name 変更された属性の識別名
  def binding_value_changed(name, old_value)
    # 名前つきコントロールの登録
    case name
    when :name
      v = root.view
      v.unregister_control(old_value, self)
      if n = self.name
        v.register_control(n, self)
      end
    end
    execute_callback(:binding_value_changed, name, old_value)

    # 再整列が必要か
    unless stable_in_placement?(name)
      disarrange
    end

    # 再描画が必要か
    unless stable_in_appearance?(name)
      corrupt
    end
  end
  
  # @return [Boolean] 指定された属性が変更された際に再整列が必要とならないか
  # @param [Symbol] name 属性名
  def stable_in_placement?(name)
    case name
    when :name
      true
    else
      false
    end
  end
  
  # @return [Boolean] 指定された属性が変更された際に再描画が必要とならないか
  # @param [Symbol] name 属性名
  def stable_in_appearance?(name)
    case name
    when :name
      true
    else
      false
    end
  end

  # 再整列が必要な状態にする
  # @param [Control::Base|NilClass] 最整列を要求したコントロール
  def disarrange(control = nil)
    parent.disarrange(control || self)
  end

  # 最整列が必要か
  def disarranged?; @disarranged; end

  # 自分の子以下を再整列する
  def rearrange; end

  # 再描画が必要な状態にする
  def corrupt
    if control = render_target
      control.be_corrupted
    end
  end
  
  # レイアウト完了を通知する
  def notify_of_layouted
    execute_callback(:layouted)
    iterate_sub_controls(:notify_of_layouted)
  end

  # import完了を通知する
  def notify_of_imported
    execute_callback(:imported)
    iterate_sub_controls(:notify_of_imported)
  end
  
  # Viewport設定を通知する
  def notify_of_viewport
    execute_callback(:viewport)
    iterate_sub_controls(:notify_of_viewport)
  end
  
  # 任意のイベントを全コントロールに通知する
  def notify_of(event)
    execute_callback(event)
    iterate_sub_controls(:notify_of, event)
  end

private
  # 終了処理の実装
  def impl_finalize
  end
  
  # 更新処理の実装
  def impl_update
  end
  
  # 描画処理の実装
  def impl_draw
  end

  # 計測処理の実装
  def impl_measure(available_width, available_height)
  end

  # 配置処理の実装
  def impl_arrange(final_x, final_y, final_w, final_h)
  end
  
  # width/height を min/max の間の中に正規化する
  def adjust_desired_size_to_be_in_min_max(available_width, available_height)
    max_w = max_width
    min_w = min_width
    if max_w || min_w
      @desired_width = Utility::Math.clamp(
        min_w && Size.to_actual_value(min_w, available_width) || @desired_width,
        max_w && Size.to_actual_value(max_w, available_width) || @desired_width,
        @desired_width
      )
    end
    
    max_h = max_height
    min_h = min_height
    if max_h || min_h
     @desired_height = Utility::Math.clamp(
      min_h && Size.to_actual_value(min_h, available_height) || @desired_height,
      max_h && Size.to_actual_value(max_h, available_height) || @desired_height,
      @desired_height
     ) 
    end
  end

  # desired_width/height を数値にする
  def actualize_desired_size(available_width, available_height)
    @desired_width = Size.to_actual_value(width, available_width)
    @desired_height = Size.to_actual_value(height, available_height)
  end

  # スクリーン座標、コントロールのサイズを計算する
  def actualize_position_and_size(final_x, final_y, final_w, final_h)
    @screen_x = final_x
    @screen_y = final_y
    @actual_width = final_w
    @actual_height = final_h
  end
  
  # 子コントロールがあればその全体のメソッドを呼び出す
  # @param [Symbol] method 呼び出すメソッド名
  def iterate_sub_controls(method, *args); end

end
