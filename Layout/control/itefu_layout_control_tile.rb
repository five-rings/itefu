=begin
  Layoutシステム/指定されたサイズでコントロールを敷き詰める  
=end
class Itefu::Layout::Control::Tile < Itefu::Layout::Control::Composite
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Orientable
  include Itefu::Layout::Control::Ordering::Table
  attr_bindable :tile_width, :tile_height
  attr_bindable :content_alignment
  
  def default_content_alignment; Alignment::CENTER; end
  DEFAULT_TILE_SIZE = 32
  
  def initialize(parent, tile_width = nil, tile_height = nil)
    super(parent)
    self.content_alignment = default_content_alignment
    self.tile_width  = tile_width  || DEFAULT_TILE_SIZE
    self.tile_height = tile_height || DEFAULT_TILE_SIZE
  end

  def inner_width
    @inner_width || super
  end
  
  def inner_height
    @inner_height || super
  end


private

  # 計測
  def impl_measure(available_width, available_height)
    controls = children_that_takes_space
    tw = Size.to_actual_value(self.tile_width, desired_content_width)
    th = Size.to_actual_value(self.tile_height, desired_content_height)

    # 子コントロールのサイズは常に指定サイズ固定
    controls.each do |child|
      child.measure(tw - child.margin.width, th - child.margin.height)
    end

    # Size::AUTOの場合には内容にフィットするサイズにする
    case orientation
    when Orientation::HORIZONTAL
      if width == Size::AUTO 
        if mw = max_width
          mw = Size.to_actual_value(mw, desired_content_width)
          dw = controls.size * tw + padding.width
          if dw <= mw
            num_row = children.size
            num_col = 1
          end
        else
          num_row = children.size
          num_col = 1
        end
      end

      if num_row && num_col
        # コンテンツサイズにフィットする
        @desired_width = controls.size * tw + padding.width
        @inner_width = nil
      else
        # 領域内に収まるように計算する
        num_row = (desired_content_width / tw).floor
        num_col = (children.size / num_row.to_f).ceil
        @inner_width = num_row * tw
      end
      @desired_height = num_col * th + padding.height if height == Size::AUTO
      @inner_height  = num_col * th
    when Orientation::VERTICAL
      if height == Size::AUTO
        if mh = max_height
          mh = Size.to_actual_value(mh, desired_content_height)
          dh = controls.size * th + padding.height
          if dh <= mh
            num_row = children.size
            num_col = 1
          end
        else
          num_row = children.size
          num_col = 1
        end
      end

      if num_row && num_col
        # コンテンツサイズにフィットする
        @desired_height = controls.size * th + padding.height
        @inner_height = nil
      else
        # 領域内に収まるように計算する
        num_row = (desired_content_height / th).floor
        num_col = (children.size / num_row.to_f).ceil
        @inner_height = num_row * th
      end
      @desired_width = num_col * tw + padding.width if width == Size::AUTO
      @inner_width  = num_col * tw
    else
      raise Exception::Unreachable
    end
  end
  
  # 整列
  def impl_arrange(final_x, final_y, final_w, final_h)
    controls = children_that_takes_space
    orientator = orientation_storategy
    method_align_phase, method_align_offset = orientator.pola_from_xywh(:pos_x_alignmented, :pos_y_alignmented)
    plalign, oaalign = orientator.pola_from_xywh(horizontal_alignment, vertical_alignment)
    dummy = DummyContent::TEMP

    # 子コントロール全体の領域を、このコントロールの描画領域内で整列させる
    dummy.content_width  = inner_width
    dummy.content_height = inner_height
    dummy.content_left = dummy.content_top = 0
    content_phase = self.send(method_align_phase, self, dummy, plalign)
    content_offset = self.send(method_align_offset, self, dummy, oaalign)

    tw = Size.to_actual_value(self.tile_width, content_width)
    th = Size.to_actual_value(self.tile_height, content_height)
    tp, to = orientator.pola_from_xywh(tw, th)

    # 子コントロール個々の領域をタイルサイズにする
    dummy.content_width  = tw
    dummy.content_height = th

    line_length = 0
    line_count = 0
    calign = content_alignment
    content_length = self.send(orientator::ContentLength)
    child_phase = content_phase
    child_offset = content_offset

    # 子コントロールのarrange
    controls.each do |child|
      child_full_length = child.send(orientator::DesiredFullLength)
      line_length += child_full_length
      if line_length > content_length && line_count > 0
        child_offset += to
        child_phase = content_phase
        line_length = child_full_length
        line_count = 0
      end

      # 整列
      orientator.arrange(
        child,
        # 進行方向の位置
        self.send(method_align_phase, dummy, child, Alignment::LEFT) + child_phase,
        # 直交方向の整列済み位置
        child_offset + self.send(method_align_offset, dummy, child, calign),
        # サイズ
        child.send(orientator::DesiredLength),
        child.send(orientator::DesiredAmplitude)
      )
      # 表示位置を進行方向へずらす
      child_phase += child_full_length
      line_count += 1
    end # of each
  end

  # 描画
  def impl_draw
    # 順に並べるので、画面内にくるまでと、はみ出してからのものは、まとめてスキップできる
    controls = children_that_takes_space
    partial_draw(controls)
  end


private

  def next_child_index(operation, child_index)
    case orientation
    when Orientation::HORIZONTAL
      tw = Size.to_actual_value(self.tile_width, content_width)
      row = (content_width / tw).floor
      case operation
      when Operation::MOVE_LEFT
        prev_ordering_index(child_index, children.size, row)
      when Operation::MOVE_RIGHT
        next_ordering_index(child_index, children.size, row)
      when Operation::MOVE_UP
        up_ordering_index(child_index, children.size, row)
      when Operation::MOVE_DOWN
        down_ordering_index(child_index, children.size, row)
      end
    when Orientation::VERTICAL
      th = Size.to_actual_value(self.tile_height, content_height)
      col = (content_height / th).floor
      case operation
      when Operation::MOVE_UP
        prev_ordering_index(child_index, children.size, col)
      when Operation::MOVE_DOWN
        next_ordering_index(child_index, children.size, col)
      when Operation::MOVE_LEFT
        up_ordering_index(child_index, children.size, col)
      when Operation::MOVE_RIGHT
        down_ordering_index(child_index, children.size, col)
      end
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
    # -1:先頭 0:中央 :末尾
    case horizontal_alignment
    when Alignment::LEFT
      hp = -1
    when Alignment::RIGHT
      hp = 1
    else
      hp = 0
    end
    
    case vertical_alignment
    when Alignment::TOP
      vp = -1
    when Alignment::BOTTOM
      vp = 1
    else
      vp = 0
    end

    case operation
    when Operation::MOVE_LEFT
      r = 1
      c = vp
    when Operation::MOVE_RIGHT
      r = -1
      c = vp
    when Operation::MOVE_UP
      r = hp
      c = 1
    when Operation::MOVE_DOWN
      r = hp
      c = -1
    else
      return super
    end
    
    # r,c = [-1,0,1] を処理する
    size = children.size
    case orientation
    when Orientation::HORIZONTAL
      tw = Size.to_actual_value(self.tile_width, content_width)
      row = (content_width / tw).floor
      col = (size / row.to_f).ceil
      r = (row - 1) * (r + 1) / 2
      c = (col - 1) * (c + 1) / 2
      c * row + r
    when Orientation::VERTICAL
      th = Size.to_actual_value(self.tile_height, content_height)
      col = (content_height / th).floor
      row = (size / col.to_f).ceil
      r = (row - 1) * (r + 1) / 2
      c = (col - 1) * (c + 1) / 2
      r * col + c
    else
      raise Exception::Unreachable
    end
  end

end
