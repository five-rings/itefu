=begin
  Layoutシステム/項目の順序関係を定義する
=end
module Itefu::Layout::Control::Ordering

  # 前後方向に項目を選ぶ
  module Linear
    include Itefu::Layout::Definition

    def next_ordering_index(index, size)
      Utility::Math.wrap(0, size - 1, index + 1)
    end
    
    def prev_ordering_index(index, size)
      Utility::Math.wrap(0, size - 1, index - 1)
    end
  end
  
  # 上下左右に項目を選ぶ
  module Table
    include Itefu::Layout::Definition

    def next_ordering_index(index, size, row_count)
      min = index - (index % row_count)
      max = Utility::Math.min(min + row_count, size) - 1
      Utility::Math.wrap(min, max, index + 1)
    end

    def prev_ordering_index(index, size, row_count)
      min = index - (index % row_count)
      max = Utility::Math.min(min + row_count, size) - 1
      Utility::Math.wrap(min, max, index - 1)
    end
    
    def up_ordering_index(index, size, row_count)
      min = index % row_count
      tail, pos = (size - 1).divmod(row_count)
      if pos < min
        max = min + (tail - 1) * row_count
      else
        max = min + tail * row_count
      end
      Utility::Math.wrap(min, max, index - row_count)
    end
    
    def down_ordering_index(index, size, row_count)
      min = index % row_count
      tail, pos = (size - 1).divmod(row_count)
      if pos < min
        max = min + (tail - 1) * row_count
      else
        max = min + tail * row_count
      end
      Utility::Math.wrap(min, max, index + row_count)
    end
  end
  
  # スクリーン座標で一番近い項目を選ぶ
  module Nearest
    include Itefu::Layout::Definition
    
    # currentに計算用のダミーを与えたい時用
    class Dummy < Rect
      def screen_x; x; end
      def screen_y; y; end
      def actual_width; width; end
      def actual_height; height; end
    end
    Dummy.const_set(:TEMP, Dummy.new)

    def up_ordering_control(current, owner)
      return unless current
      base_y = current.screen_y + current.actual_height / 2

      selectables = owner.children.select(&:selectable?)
      candidates = selectables.select {|child| base_y > child.screen_y + child.actual_height / 2 }
      if candidates.empty?
        base_y = owner.inner_height + base_y
        candidates = selectables.select {|child| base_y > child.screen_y + child.actual_height / 2 }
      end
      
      center_x = current.screen_x + current.actual_width / 2
      center_y = base_y
      nearest = candidates.min_by {|child|
        (center_x - child.screen_x - child.actual_width/2) ** 2 +
        (center_y - child.screen_y - child.actual_height/2) ** 2
      }

      nearest
    end

    def down_ordering_control(current, owner)
      return unless current
      base_y = current.screen_y + current.actual_height / 2

      selectables = owner.children.select(&:selectable?)
      candidates = selectables.select {|child| base_y < child.screen_y + child.actual_height / 2 }
      if candidates.empty?
        base_y = base_y - owner.inner_height
        candidates = selectables.select {|child| base_y < child.screen_y + child.actual_height / 2 }
      end
      
      center_x = current.screen_x + current.actual_width / 2
      center_y = base_y
      nearest = candidates.min_by {|child|
        (center_x - child.screen_x - child.actual_width/2) ** 2 +
        (center_y - child.screen_y - child.actual_height/2) ** 2
      }

      nearest
    end

    def left_ordering_control(current, owner)
      return unless current
      base_x = current.screen_x + current.actual_width / 2

      selectables = owner.children.select(&:selectable?)
      candidates = selectables.select {|child| base_x > child.screen_x + child.actual_width / 2 }
      if candidates.empty?
        base_x = owner.inner_width + base_x
        candidates = selectables.select {|child| base_x > child.screen_x + child.actual_width / 2 }
      end
      
      center_x = base_x
      center_y = current.screen_y + current.actual_height / 2
      nearest = candidates.min_by {|child|
        (center_x - child.screen_x - child.actual_width/2) ** 2 +
        (center_y - child.screen_y - child.actual_height/2) ** 2
      }

      nearest
    end

    def right_ordering_control(current, owner)
      return unless current
      base_x = current.screen_x + current.actual_width / 2

      selectables = owner.children.select(&:selectable?)
      candidates = selectables.select {|child| base_x < child.screen_x + child.actual_width / 2 }
      if candidates.empty?
        base_x = base_x - owner.inner_width
        candidates = selectables.select {|child| base_x < child.screen_x + child.actual_width / 2 }
      end
      
      center_x = base_x
      center_y = current.screen_y + current.actual_height / 2
      nearest = candidates.min_by {|child|
        (center_x - child.screen_x - child.actual_width/2) ** 2 +
        (center_y - child.screen_y - child.actual_height/2) ** 2
      }

      nearest
    end
  end

end
