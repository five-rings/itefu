=begin
  Layoutシステム/複数の子コントロールを一列に並べるコントロール
=end
class Itefu::Layout::Control::Lineup < Itefu::Layout::Control::Composite
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Orientable
  include Itefu::Layout::Control::Ordering::Linear
  attr_bindable :content_reverse # 子を逆から配置する

  
  def initialize(*args)
    super
    @dummy_content = DummyContent.new
  end

  def inner_width
    @dummy_content.content_width
  end
  
  def inner_height
    @dummy_content.content_height
  end


private

  # 計測
  def impl_measure(available_width, available_height)
    controls = children_that_takes_space
    # 配置は逆からにするが、残りサイズの計算はそのまま
    # 残りサイズを全て使うような子を最後に配置するときに、順序が逆になるだけでなく、レイアウト自体が大きくかわってしまうため
    # controls = controls.reverse_each if content_reverse
    orientator = orientation_storategy
    available_length, available_amplitude = orientator.pola_from_xywh(desired_content_width, desired_content_height)

    rest_of_length = available_length
    largest_amplitude = 0
    # 残りスペースを消費しながら子のサイズを計測していく
    controls.each do |child|
      rest_of_length -= child.margin.send(orientator::Length)
      orientator.measure(
        child,
        rest_of_length,
        available_amplitude - child.margin.send(orientator::Amplitude)
      )
      rest_of_length -= child.send(orientator::DesiredLength)
      # 最大の高さのものを、後の計算のために計測しておく
      largest_amplitude = Utility::Math.max(child.send(orientator::DesiredFullAmplitude), largest_amplitude)
    end
    
    # 子の中で一番大きいものの計測
    # @note arrangeで必ず使用するので、先に計算しておいて使いまわす
    @children_length = available_length - rest_of_length
    @children_amplitude = largest_amplitude
 
    # Size::AUTOの場合には内容にフィットするサイズにする   
    desired_length = @children_length + padding.send(orientator::Length) if self.send(orientator::Length) == Size::AUTO
    desired_amplitude = @children_amplitude + padding.send(orientator::Amplitude) if self.send(orientator::Amplitude) == Size::AUTO
    dw, dh = orientator.xywh_from_pola(desired_length, desired_amplitude)
    @desired_width  = dw if dw
    @desired_height = dh if dh
  end

  # 整列
  def impl_arrange(final_x, final_y, final_w, final_h)
    controls = children_that_takes_space
    controls = controls.reverse_each if content_reverse
    orientator = orientation_storategy
    method_align_phase, method_align_offset = orientator.pola_from_xywh(:pos_x_alignmented, :pos_y_alignmented)
    plalign, oaalign = orientator.pola_from_xywh(horizontal_alignment, vertical_alignment)
    dummy = @dummy_content
    
    # 子コントロール全体の領域を、このコントロールの描画領域内で整列させる
    dummy.content_width,
    dummy.content_height =
      orientator.xywh_from_pola(@children_length, @children_amplitude)
    content_phase = self.send(method_align_phase, self, dummy, plalign)
    content_offset = self.send(method_align_offset, self, dummy, oaalign)
    # 個々の子コントロールを配置するための領域を設定する
    dummy.content_left,
    dummy.content_top =
      orientator.xywh_from_pola(content_phase, content_offset)

    calign = oaalign # 常に1行なので直交方向の整列 = content_align になる
    amp_stretched = (calign == Alignment::STRETCH) && self.send(orientator::ContentAmplitude)
    child_phase = 0

    # 子コントロールのarrange
    controls.each do |child|
      if amp_stretched
        amp = amp_stretched - child.margin.send(orientator::Amplitude)
      else
        amp = child.send(orientator::DesiredAmplitude)
      end

      # 整列
      orientator.arrange(
        child,
        # 進行方向の位置
        self.send(method_align_phase, dummy, child, Alignment::LEFT) + child_phase,
        # 直交方向の整列済み位置
        self.send(method_align_offset, dummy, child, calign),
        # サイズ
        child.send(orientator::DesiredLength),
        amp
      )
      # 表示位置を進行方向へずらす
      child_phase += child.send(orientator::DesiredFullLength)
    end
  end

  # 描画
  def impl_draw
    # 順に並べるので、画面内にくるまでと、はみ出してからのものは、まとめてスキップできる
    controls = children_that_takes_space
    controls = controls.reverse_each if content_reverse
    partial_draw(controls)
  end


public

  def next_child_index(operation, child_index)
    case orientation
    when Orientation::HORIZONTAL
      case operation
      when Operation::MOVE_LEFT
        prev_ordering_index(child_index, children.size)
      when Operation::MOVE_RIGHT
        next_ordering_index(child_index, children.size)
      else
        child_index
      end
    when Orientation::VERTICAL
      case operation
      when Operation::MOVE_UP
        prev_ordering_index(child_index, children.size)
      when Operation::MOVE_DOWN
        next_ordering_index(child_index, children.size)
      else
        child_index
      end
    end
  end
  
  def child_index_wrapped?(operation, child_index, old_index)
    case orientation
    when Orientation::HORIZONTAL
      case operation
      when Operation::MOVE_LEFT
        child_index >= old_index
      when Operation::MOVE_RIGHT
        child_index <= old_index
      when Operation::MOVE_UP, Operation::MOVE_DOWN
        true
      end
    when Orientation::VERTICAL
      case operation
      when Operation::MOVE_UP
        child_index >= old_index
      when Operation::MOVE_DOWN
        child_index <= old_index
      when Operation::MOVE_LEFT, Operation::MOVE_RIGHT
        true 
      end
    end
  end
  
  def default_child_index(operation)
    case orientation
    when Orientation::HORIZONTAL
      case operation
      when Operation::MOVE_LEFT
        children.size - 1
      when Operation::MOVE_RIGHT
        0
      else
        case horizontal_alignment
        when Alignment::LEFT
          0
        when Alignment::RIGHT
          children.size - 1
        else
          children.size / 2
        end
      end
    when Orientation::VERTICAL
      case operation
      when Operation::MOVE_UP
        children.size - 1
      when Operation::MOVE_DOWN
        0
      else
        case vertical_alignment
        when Alignment::TOP
          0
        when Alignment::BOTTOM
          children.size - 1
        else
          children.size / 2
        end
      end
    else
      super
    end
  end

end
