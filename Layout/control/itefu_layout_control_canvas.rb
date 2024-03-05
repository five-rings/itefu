=begin
  Layoutシステム/自由な位置に複数の子コントロールを配置できるコントロール
=end
class Itefu::Layout::Control::Canvas < Itefu::Layout::Control::Composite
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Ordering::Nearest

  def inner_width
    c = children_that_takes_space.max_by {|child| child.full_width }
    c && c.full_width || super
  end
  
  def inner_height
    c = children_that_takes_space.max_by {|child| child.full_height }
    c && c.full_height || super
  end


private

  # 計測
  def impl_measure(available_width, available_height)
    dw = 0 if width  == Size::AUTO
    dh = 0 if height == Size::AUTO
    children_that_takes_space.each do |child|
      child.measure(desired_content_width - child.margin.width, desired_content_height - child.margin.height)
      dw = Utility::Math.max(dw, child.desired_full_width)  if dw
      dh = Utility::Math.max(dh, child.desired_full_height) if dh
    end
    @desired_width  = dw + padding.width  if dw
    @desired_height = dh + padding.height if dh
  end

  # 整列
  def impl_arrange(final_x, final_y, final_w, final_h)
    halign  = horizontal_alignment
    valign  = vertical_alignment

    children_that_takes_space.each do |child|
      child_x = pos_x_alignmented(self, child, halign)
      child_y = pos_y_alignmented(self, child, valign)
      child_w = (halign == Alignment::STRETCH) ? content_width  - child.margin.width  : child.desired_width
      child_h = (valign == Alignment::STRETCH) ? content_height - child.margin.height : child.desired_height
      child.arrange(child_x, child_y, child_w, child_h)
    end
  end


private

  Ordering = Itefu::Layout::Control::Ordering::Nearest

  def next_child_index(operation, child_index)
    case operation
    when Operation::MOVE_LEFT
      nearest = left_ordering_control(child_at(child_index), self)
    when Operation::MOVE_RIGHT
      nearest = right_ordering_control(child_at(child_index), self)
    when Operation::MOVE_UP
      nearest = up_ordering_control(child_at(child_index), self)
    when Operation::MOVE_DOWN
      nearest = down_ordering_control(child_at(child_index), self)
    end
    nearest && find_child_index(nearest)
  end

  def child_index_wrapped?(operation, child_index, old_index)
    case operation
    when Operation::MOVE_LEFT
      child_at(child_index).screen_x >= child_at(old_index).screen_x
    when Operation::MOVE_UP
      child_at(child_index).screen_y >= child_at(old_index).screen_y
    when Operation::MOVE_RIGHT
      child_at(child_index).screen_x <= child_at(old_index).screen_x
    when Operation::MOVE_DOWN
      child_at(child_index).screen_y <= child_at(old_index).screen_y
    end
  end

  def default_child_index(operation)
    dummy = Ordering::Dummy::TEMP
    dummy.width = dummy.height = 0

    # 直交方向の位置を alignment に応じて決める
    case operation
    when Operation::MOVE_UP, Operation::MOVE_DOWN
      case horizontal_alignment
      when Alignment::LEFT
        dummy.x = self.content_left
      when Alignment::RIGHT
        dummy.x = self.content_right
      else
        dummy.x = self.content_left + self.content_width / 2
      end
    when Operation::MOVE_LEFT, Operation::MOVE_RIGHT
      case vertical_alignment
      when Alignment::TOP
        dummy.y = self.content_top
      when Alignment::BOTTOM
        dummy.y = self.content_bottom
      else
        dummy.y = self.content_top + self.content_height / 2
      end
    end
    
    # カーソルの進行方向の位置を決め、一番近いコントロールを探す
    case operation
    when Operation::MOVE_UP
      dummy.y = self.content_bottom
      nearest = up_ordering_control(dummy, self)
    when Operation::MOVE_DOWN
      dummy.y = self.content_top
      nearest = down_ordering_control(dummy, self)
    when Operation::MOVE_LEFT
      dummy.x = self.content_right
      nearest = left_ordering_control(dummy, self)
    when Operation::MOVE_RIGHT
      dummy.x = self.content_left
      nearest = right_ordering_control(dummy, self)
    end
   
    nearest && find_child_index(nearest) || super
  end
 

end
