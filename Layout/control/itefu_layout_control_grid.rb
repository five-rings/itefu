=begin
  Layoutシステム/複数の子コントロールを、事前定義に従って、枠内に並べるコントロール 
=end
class Itefu::Layout::Control::Grid < Itefu::Layout::Control::Composite
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Ordering::Table
  attr_reader :row_separators
  attr_reader :col_separators
  def column_separators; @col_separators; end
  

  module GridLayoutedItem
    extend Itefu::Layout::Control::Bindable::Extension
    attr_bindable :grid_row, :grid_col
    def grid_column; self.grid_col; end
    def grid_column=(value); self.grid_col = value; end
  end

  # 枠を横に分割する座標を指定する
  # @note コントロール内座標で指定する
  # @param [Numeric|Array<Numeric>] 分割する座標
  def add_row_separator(*args)
    @row_separators.concat(args)
  end

  # 枠を縦に分割する座標を指定する
  # @note コントロール内座標で指定する
  # @param [Numeric|Array<Numeric>] 分割する座標
  def add_col_separator(*args)
    @col_separators.concat(args)
  end
  alias :add_column_separator :add_col_separator

  def initialize(*args)
    super
    # 枠の左端の座標
    @row_separators = [0]
    # 枠の上端の座標
    @col_separators = [0]
  end

  # 子に整列用の属性を追加する
  def add_child_control(klass, *args)
    super.extend GridLayoutedItem
  end


private

  def impl_measure(available_width, available_height)
    cw = self.desired_content_width
    ch = self.desired_content_height
    rows = @row_separators.map {|v| Size.to_actual_value(v, cw) }
    cols = @col_separators.map {|v| Size.to_actual_value(v, ch) }
    
    children_that_takes_space.each do |child|
      row = child.grid_row
      col = child.grid_col
      child.measure(
        rows.fetch(row + 1, cw) - rows.at(row) - child.margin.width,
        cols.fetch(col + 1, ch) - cols.at(col) - child.margin.height
      )
    end
  end
  
  def impl_arrange(final_x, final_y, final_w, final_h)
    dummy = DummyContent::TEMP
    base_x = self.content_left
    base_y = self.content_top
    base_w = self.content_width
    base_h = self.content_height
    halign = horizontal_alignment
    valign = vertical_alignment
    rows = @row_separators.map {|v| Size.to_actual_value(v, base_w) }
    cols = @col_separators.map {|v| Size.to_actual_value(v, base_h) }
    
    children_that_takes_space.each do |child|
      row = child.grid_row
      col = child.grid_col
      dummy.content_left   = base_x + rows.at(row)
      dummy.content_top    = base_y + cols.at(col)
      dummy.content_width  = rows.fetch(row + 1, base_w) - rows.at(row)
      dummy.content_height = cols.fetch(col + 1, base_h) - cols.at(col)
      child.arrange(
        pos_x_alignmented(dummy, child, halign),
        pos_y_alignmented(dummy, child, valign),
        (halign == Alignment::STRETCH) ? dummy.content_width  - child.margin.width  : child.desired_width,
        (valign == Alignment::STRETCH) ? dummy.content_height - child.margin.height : child.desired_height
      )
    end
  end


public

  def child_at(child_index)
    return nil unless child_index
    col, row = child_index.divmod(@row_separators.size)

    children.find {|child|
      child.grid_row == row && child.grid_col == col
    }
  end
  
  def children_size
    @row_separators.size * @col_separators.size
  end
  
  def find_child_index(control = nil)
    index = super
    control = index && children[index]
    control && control.grid_col * @row_separators.size + control.grid_row
  end

 def rfind_child_index(control = nil)
    index = super
    control = index && children[index]
    control && control.grid_col * @row_separators.size + control.grid_row
  end

  def next_child_index(operation, child_index)
    row = @row_separators.size
    size = row * @col_separators.size

    case operation
    when Operation::MOVE_LEFT
      prev_ordering_index(child_index, size, row)
    when Operation::MOVE_RIGHT
      next_ordering_index(child_index, size, row)
    when Operation::MOVE_UP
      up_ordering_index(child_index, size, row)
    when Operation::MOVE_DOWN
      down_ordering_index(child_index, size, row)
    end
  end

  def child_index_wrapped?(operation, child_index, old_index)
    case operation
    when Operation::MOVE_LEFT
      child_index >= old_index
    when Operation::MOVE_RIGHT
      child_index <= old_index
    when Operation::MOVE_UP
      child_index >= old_index
    when Operation::MOVE_DOWN
      child_index <= old_index
    end
  end

  def default_child_index(operation)
    case operation
    when Operation::MOVE_LEFT
      # 右上
      @row_separators.size - 1
    when Operation::MOVE_RIGHT
      # 左上
      0
    when Operation::MOVE_UP
      # 左下
      (@col_separators.size - 1) * @row_separators.size
    when Operation::MOVE_DOWN
      # 左上
      0
    else
      0
    end
  end

end
