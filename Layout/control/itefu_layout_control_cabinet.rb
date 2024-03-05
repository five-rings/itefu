=begin
  Layoutシステム/複数の子コントロールを並べ、はみだしたら次の行に送るコントロール
=end
class Itefu::Layout::Control::Cabinet < Itefu::Layout::Control::Composite
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Orientable
  attr_bindable :content_alignment
  attr_bindable :content_reverse # 子を逆から配置する
  
  def default_content_alignment; Alignment::CENTER; end
  
  Info = Struct.new(:line_lengths, :line_amplitudes, :width, :height)
  
  def initialize(*args)
    super
    self.content_alignment = default_content_alignment
    @info = Info.new([], [], nil, nil)
    @dummy_content = DummyContent.new
  end

  def inner_width
    @info.width
  end
  
  def inner_height
    @info.height
  end
  
  def break_line
    index = children.size
    if index > 0 
      @breaking_positions ||= []
      @breaking_positions << (index - 1)
    end
  end
  
  def clear_break_lines
    @breaking_positions.clear if @breaking_positions
  end
  
  def clear_children
    clear_break_lines
    super
  end

private

  # 計測
  def impl_measure(available_width, available_height)
    controls = children_that_takes_space
    orientator = orientation_storategy
    available_length, available_amplitude = orientator.pola_from_xywh(desired_content_width, desired_content_height)
    
    info = @info
    info.line_lengths.clear
    info.line_amplitudes.clear

    line_count = 0
    line_length = 0
    line_amplitude = 0
    break_count = 0
    to_break = false

    controls.each.with_index do |child, child_index|
      next unless child.takes_space?
      
      # 改行の確認
      break_pos = @breaking_positions && @breaking_positions[break_count]
      if break_pos && (break_pos < child_index)
        to_break = true
        break_count += 1
      end

      # 前の行の改行を処理
      if to_break
        info.line_lengths << line_length
        info.line_amplitudes << line_amplitude
        available_amplitude -= line_amplitude
        line_length = 0
        line_amplitude = 0
        line_count = 0
        to_break = false
      end

      # ひとまず計測してみる
      prev_line_length = line_length
      line_length += child.margin.send(orientator::Length)
      if line_length <= available_length
        orientator.measure(
          child,
          available_length - line_length,
          available_amplitude - child.margin.send(orientator::Amplitude)
        )
        line_length += child.send(orientator::DesiredLength)
      end
      
      # 計測した結果に応じて処理
      if line_length < available_length
        # まだ同じ行に積める
        line_amplitude = Utility::Math.max(child.send(orientator::DesiredFullAmplitude), line_amplitude)
        line_count += 1
      elsif line_length > available_length && line_count > 0
        # はみ出していたので次の行へ送り込む
        info.line_lengths << prev_line_length
        info.line_amplitudes << line_amplitude
        available_amplitude -= line_amplitude
        line_length = 0
        line_amplitude = 0
        line_count = 0
        redo # はみ出した分を再度計測しなおす
      else
        # ちょうどか、単体で枠をはみ出す大きさだったので、次からは次の行へ
        line_amplitude = Utility::Math.max(child.send(orientator::DesiredFullAmplitude), line_amplitude)
        line_count += 1
        to_break = true
      end
    end # of each

    # 最後の行の分を処理する
    if line_count > 0
      info.line_lengths << line_length
      info.line_amplitudes << line_amplitude
    end

    # 全体のサイズを計算
    max_len = info.line_lengths.max || 0
    max_amp = info.line_amplitudes.inject(0, &:+)
    info.width, info.height = orientator.xywh_from_pola(max_len, max_amp)
    
    # Size::AUTOの場合には内容にフィットするサイズにする   
    @desired_width  = info.width  + padding.width  if width  == Size::AUTO
    @desired_height = info.height + padding.height if height == Size::AUTO
  end

  # 整列
  def impl_arrange(final_x, final_y, final_w, final_h)
    return if children.empty?
    controls = children_that_takes_space
    orientator = orientation_storategy
    method_align_phase, method_align_offset = orientator.pola_from_xywh(:pos_x_alignmented, :pos_y_alignmented)
    plalign, oaalign = orientator.pola_from_xywh(horizontal_alignment, vertical_alignment)
    info = @info
    dummy = @dummy_content


    # 子コントロール全体の領域を、このコントロールの描画領域内で整列させる
    dummy.content_width  = info.width
    dummy.content_height = info.height
    dummy.content_left = dummy.content_top = 0
    content_offset = self.send(method_align_offset, self, dummy, oaalign)
    
    if content_reverse
      controls = controls.reverse_each
      line_sign = -1
      line_index = -1
    else
      line_sign = 1
      line_index = 0
    end
    line_count = 0
    line_length = 0
    calign = content_alignment
    content_length = self.send(orientator::ContentLength)
    break_count = 0
    to_break = false

    # 配置の開始位置
    dummy.content_width,
    dummy.content_height =
      orientator.xywh_from_pola(info.line_lengths[line_index], info.line_amplitudes[line_index])
    child_phase = self.send(method_align_phase,  self, dummy, plalign)
    child_offset = content_offset

    # 子コントロールのarrange
    controls.each.with_index do |child, child_index|
      child_full_length = child.send(orientator::DesiredFullLength)
      line_length += child_full_length

      break_pos = @breaking_positions && @breaking_positions[break_count]
      if break_pos && (break_pos < child_index)
        break_count += 1
        to_break = true
      end

      if (line_length > content_length && line_count > 0) || to_break
        # 次の行へ:表示位置を直交方向へずらす
        child_offset += info.line_amplitudes[line_index]
        line_length = child_full_length
        line_index += line_sign
        line_count = 0
        dummy.content_width,
        dummy.content_height =
          orientator.xywh_from_pola(info.line_lengths[line_index], info.line_amplitudes[line_index])
        child_phase = self.send(method_align_phase,  self, dummy, plalign)
        to_break = false
      end

      if (calign == Alignment::STRETCH)
        amp = info.line_amplitudes[line_index] - child.margin.send(orientator::Amplitude)
      else
        amp = child.send(orientator::DesiredAmplitude)
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
        amp
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
    controls = controls.reverse_each if content_reverse
    partial_draw(controls)
  end


public

  module Ordering
    module Linear
      extend Itefu::Layout::Control::Ordering::Linear
    end
    module Nearest
      include Itefu::Layout::Control::Ordering::Nearest
      extend Itefu::Layout::Control::Ordering::Nearest
    end
  end

  def next_child_index(operation, child_index)
    case orientation
    when Orientation::HORIZONTAL
      case operation
      when Operation::MOVE_LEFT
        Ordering::Linear.prev_ordering_index(child_index, children.size)
      when Operation::MOVE_RIGHT
        Ordering::Linear.next_ordering_index(child_index, children.size)
      when Operation::MOVE_UP
        nearest = Ordering::Nearest.up_ordering_control(child_at(child_index), self)
        find_child_index(nearest)
      when Operation::MOVE_DOWN
        nearest = Ordering::Nearest.down_ordering_control(child_at(child_index), self)
        find_child_index(nearest)
      end
    when Orientation::VERTICAL
      case operation
      when Operation::MOVE_UP
        Ordering::Linear.prev_ordering_index(child_index, children.size)
      when Operation::MOVE_DOWN
        Ordering::Linear.next_ordering_index(child_index, children.size)
      when Operation::MOVE_LEFT
        nearest = Ordering::Nearest.left_ordering_control(child_at(child_index), self)
        find_child_index(nearest)
      when Operation::MOVE_RIGHT
        nearest = Ordering::Nearest.right_ordering_control(child_at(child_index), self)
        find_child_index(nearest)
      end
    end
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
    dummy = Ordering::Nearest::Dummy::TEMP
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
      nearest = Ordering::Nearest.up_ordering_control(dummy, self)
    when Operation::MOVE_DOWN
      dummy.y = self.content_top
      nearest = Ordering::Nearest.down_ordering_control(dummy, self)
    when Operation::MOVE_LEFT
      dummy.x = self.content_right
      nearest = Ordering::Nearest.left_ordering_control(dummy, self)
    when Operation::MOVE_RIGHT
      dummy.x = self.content_left
      nearest = Ordering::Nearest.right_ordering_control(dummy, self)
    end
   
    nearest && find_child_index(nearest) || super
  end
  
end
