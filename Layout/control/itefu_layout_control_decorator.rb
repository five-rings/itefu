=begin
  Layoutシステム/子を一つだけもつコントロール
=end
class Itefu::Layout::Control::Decorator < Itefu::Layout::Control::Base
  include Itefu::Layout::Control::Alignmentable
  attr_reader :child    # [Control::Base] 子コントロール
  
  def initialize(*args)
    super
    @child = nil
  end
  
  # 終了処理
  def impl_finalize
    clear_child
  end
  
  # コントロールを生成し子コントロールにする
  # @param [Class] klass 生成するコントロールの型
  # @param [Array] args 生成時に渡す任意の引数
  # @return [Control::Base] 追加したコントロール
  def add_child_control(klass, *args)
    ITEFU_DEBUG_ASSERT(child.nil?)
    disarrange
    @child = create_child_control(klass, *args)
  end

  # 子コントロールを解放する  
  def clear_child
    child.finalize if child
    @child = nil
  end
  
  # 子コントロールのメソッドを呼ぶ
  def iterate_sub_controls(method, *args)
    child.send(method, *args) if child
  end

  # 計測
  def impl_measure(available_width, available_height)
    if child && child.takes_space?
      # 占有する
      child.measure(desired_content_width - child.margin.width, desired_content_height - child.margin.height)
      @desired_width  = padding.width  + child.desired_full_width  if width  == Size::AUTO
      @desired_height = padding.height + child.desired_full_height if height == Size::AUTO
    else
      # 子は表示されない
      @desired_width  = padding.width  if width  == Size::AUTO
      @desired_height = padding.height if height == Size::AUTO
    end
  end

  # 整列
  def impl_arrange(final_x, final_y, final_w, final_h)
    return unless child && child.takes_space?
    halign  = horizontal_alignment
    valign  = vertical_alignment
    child_x = pos_x_alignmented(self, child, halign)
    child_y = pos_y_alignmented(self, child, valign)
    child_w = (halign == Alignment::STRETCH) ? content_width  - child.margin.width  : child.desired_width
    child_h = (valign == Alignment::STRETCH) ? content_height - child.margin.height : child.desired_height
    child.arrange(child_x, child_y, child_w, child_h)
  end

  # 再整列が必要な状態にする
  def disarrange(control = nil)
    if control && self.width != Size::AUTO && self.height != Size::AUTO
      @disarranged = true
    else
      super
    end
  end

  # 再整列
  def rearrange
    if @disarranged
      impl_measure(self.content_width, self.content_height)
      impl_arrange(self.screen_x, self.screen_y, self.actual_width, self.actual_height)
      @disarranged = false
    else
      child.rearrange if child
    end
  end

  # 更新
  def impl_update
    child.update if child
  end
  
  # 描画
  def impl_draw
    child.draw if child && child.visible?
  end
  
  def inner_width
    if child && child.takes_space?
      child.full_width
    else
      super
    end
  end
  
  def inner_height
    if child && child.takes_space?
      child.full_height
    else
      super
    end
  end

end
