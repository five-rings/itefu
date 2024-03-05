=begin
  Layoutシステム/数値入力コントロール
=end
class Itefu::Layout::Control::Dial < Itefu::Layout::Control::Label
  include Itefu::Layout::Control::Drawable
  include Itefu::Layout::Control::Font
  include Itefu::Layout::Control::Focusable
  include Itefu::Layout::Control::Scrollable
#ifdef :ITEFU_DEVELOP
  # カーソルなしのDialは考えられないので、Dial自身でカーソルを処理する
  # そのためControl::CursorをDialにmix-inすることはできない
  include Utility::Module.unexpect_for(Itefu::Layout::Control::Cursor)
  extend Utility::Module.unexpect_for(Itefu::Layout::Control::Cursor)
#endif
  attr_bindable :max_number     # [Fixnum] 最大値
  attr_bindable :min_number     # [Fixnum] 最小値
  attr_bindable :loop           # [Boolean] 最大値と最小値をループさせるか
  alias :number :text           # [Fixnum] 現在値 (このコントロールから変更される)
  alias :number= :text=
  private :text, :text=
  attr_accessor :cursor_index   # 現在操作中の桁(最大の桁=0)

  # 決定時に呼ばれる
  def on_decide_effect(index); end
  # キャンセル時に呼ばれる
  def on_cancel_effect(index); end
  # 選択している桁を変える際に呼ばれる
  def on_cursor_changing_effect(index); end
  # 値を変更する際に呼ばれる
  def on_value_changing_effect(index, new_value, old_value); end

  def initialize(parent)
    super
    self.number = 0
    @cursor_index = 0
  end

  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :max_number
      @text_rect = nil
    when :min_number
      @text_rect = nil if self.min_number > self.number
    end
    super
  end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :text
      # フォントがプロポーショナルだと桁数が同じでも常に変わる可能性がある
      super
    when :max_number
      # max_numberが変わると横幅が変わり得るが横幅指定なら変わらない
      (width != Size::AUTO)
    when :min_number
      if self.max_number
        true
      else
        self.min_number < self.number
      end
    else
      super
    end
  end

  # 何かしらの操作が行われたときに呼ばれる
  def on_operation_instructed(operation, *args)
    case operation
    when Operation::DECIDE
      x, y = args
      operate_decide(x, y)
    when Operation::CANCEL
      operate_cancel
    when Operation::MOVE_POSITION
      x, y = args
      operate_select(x, y) if x && y
    when Operation::MOVE_LEFT
      operate_move_up
    when Operation::MOVE_RIGHT
      operate_move_down
    when Operation::MOVE_UP
      operate_increase
    when Operation::MOVE_DOWN
      operate_decrease
    end
  end

  def parent_window
    render_target && render_target.recent_ancestor(Itefu::Layout::Control::Window)
  end

  def draw
    draw_cursor
    super
  end

  def draw_cursor
    return unless index = @cursor_changed
    @cursor_changed = nil
    reset_cursor_rect(index)
  end

  def reset_cursor_rect(index)
    return unless target = parent_window

    if index > 0
      offset = @number_borders[index - 1]
    else
      offset = 0
    end

    # dw = @number_borders[index] - offset
    # 縁取りなどの分のサイズを計算しなおす
    dw = 0
    use_bitmap_applying_font(Itefu::Rgss3::Bitmap.empty, font) do |buffer|
      dw = buffer.rich_text_size(text[index], false).width
    end

    x = self.screen_x + self.padding.left
    y = self.screen_y + self.padding.right
    text_width  = @text_rect && @text_rect.width  || content_width
    text_height = @text_rect && @text_rect.height || content_height
    nooutline = font && font.outline.!

    case vertical_alignment
    when Alignment::TOP
      y = y
    when Alignment::BOTTOM
      y = y + content_height - text_height
    else # center, stretch
      y = y + (content_height - text_height) / 2
      y = nooutline ? y : y - 1
    end

    case horizontal_alignment
    when Alignment::LEFT
      x = nooutline ? x : x - 1
    when Alignment::RIGHT
      x = x + content_width - text_width
    else # center, stretch
      x = x + (content_width - text_width) / 2
    end

    target.window.active = true
    # ウィンドウのカーソルを設定
    target.cursor_rect = Box::TEMP.set(
      y,
      x + offset + dw,
      y + text_height,
      x + offset
     )
  end

  def on_focused
    digit = Utility::String.digit(self.max_number || self.number)
    @cursor_changed = @cursor_index = Utility::Math.max(0, digit - 1)
  end

  def on_unfocused
    if target = parent_window
      target.cursor_rect = nil
    end
  end

  def scroll(value)
    if value > 0
      operate_decrease
    elsif value < 0
      operate_increase
    end
  end

  # 指定した桁数の数値を上げる(桁上がり桁下がりし得る)
  def change_dial_value(index, sign)
    num = self.number
    minnum = self.min_number || 0
    maxnum = self.max_number
    loop = self.loop
    if loop && sign > 0 && maxnum && num == maxnum
      newnum = self.number = minnum
    elsif loop && sign < 0 && maxnum && num == minnum
      newnum = self.number = maxnum
    else
      digit = Utility::String.digit(maxnum || num)
      newnum = num + sign * 10 ** (digit - index - 1)
      newnum = Utility::Math.clamp_with_nil(minnum, maxnum, newnum)
      self.number = newnum
    end

    on_value_changing_effect(index, num, newnum)
    execute_callback(:value_changed, index, num, newnum)
  end

protected

  # 決定操作を行う
  # @note x, yはnilを指定しても良い
  def operate_decide(x, y)
    if x && y
      return unless target = parent_window
      sx = self.screen_x
      sy = self.screen_y
      if y < sy
        operate_increase
      elsif y > sy + self.actual_height
        operate_decrease
      elsif x < sx
        operate_move_up
      elsif x > sx + self.actual_width
        operate_move_down
      else
        on_decide_effect(@cursor_index)
        execute_callback(:decided, @cursor_index, x, y)
      end
    else
      on_decide_effect(@cursor_index)
      execute_callback(:decided, @cursor_index, x, y)
    end
  end

  # キャンセル操作を行う
  def operate_cancel
    on_cancel_effect(@cursor_index)
    execute_callback(:canceled, @cursor_index)

    pop_focus
  end

  # カーソルの移動操作を行う
  def operate_move_up
    index = @cursor_index
    @cursor_index -= 1
    if @cursor_index < 0
      digit = Utility::String.digit(self.max_number || self.number)
      @cursor_index = Utility::Math.max(0, digit - 1)
    end
    if @cursor_index != index
      @cursor_changed = @cursor_index
      on_cursor_changing_effect(index)
      execute_callback(:cursor_changed, index)
    end
  end

  def operate_move_down
    index = @cursor_index
    @cursor_index += 1
    digit = Utility::String.digit(self.max_number || self.number)
    if @cursor_index >= digit
      @cursor_index = 0
    end
    if @cursor_index != index
      @cursor_changed = @cursor_index
      on_cursor_changing_effect(index)
      execute_callback(:cursor_changed, index)
    end
  end

  # カーソルの選択操作を行う
  def operate_select(x, y)
    x -= self.content_left
    return if x < 0 || x > self.content_width
    y -= self.content_top
    return if y < 0 || y > self.content_height

    index = (@number_borders.rindex {|b| x > b } || -1) + 1
    if index < @number_borders.size && index != @cursor_index
      @cursor_index = @cursor_changed = index
      on_cursor_changing_effect(index)
      execute_callback(:cursor_changed, index)
    end
  end

  # ダイアルの値を増やす
  def operate_increase
    change_dial_value(@cursor_index, 1)
  end

  # ダイアルの値を減らす
  def operate_decrease
    change_dial_value(@cursor_index, -1)
  end

  # 設定してある数値を画面表示用の文字列に変換して返す
  def text
    maxnum = max_number
    digit = maxnum && Utility::String.digit(maxnum) || 0
    text = Utility::String.number_with_leading(self.number, digit)
  end

private
  def update_text_rect
    update_number_rect unless @text_rect
    super
    reset_cursor_rect(@cursor_index) if focused?
  end

  # 各数値の座標の境界値を計算しておく
  def update_number_rect
    digit = Utility::String.digit(self.max_number || self.number)
    text = self.text
    use_bitmap_applying_font(Itefu::Rgss3::Bitmap.empty, font) do |buffer|
      @number_borders = 1.upto(text.length).map {|len|
        buffer.text_size(text[0, len]).width
      }
    end
  end

end
