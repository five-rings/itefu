=begin
  Layoutシステム/顔グラフィックを表示するコントロール
=end
class Itefu::Layout::Control::Face < Itefu::Layout::Control::Bitmap
  attr_bindable :face_index     # [Fixnum] アトラス上のフェイスindex

  # アトラス上の顔グラフィック一つのサイズ
  SIZE = Itefu::Rgss3::Definition::Face::SIZE

  def load_image(name, *args)
    # グラフィック名をファイル名に変換して読み込む
    super(Itefu::Rgss3::Definition::Face.filename(name), *args)
  end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :image_source, :face_index
      # どの顔画像を選んでもサイズには影響しない
      true
    else
      super
    end
  end
  
  # 計測
  def impl_measure(available_width, available_height)
    # オートサイズの場合はドットバイドットになるサイズにする
    @desired_width  = SIZE + padding.width  if width  == Size::AUTO
    @desired_height = SIZE + padding.height if height == Size::AUTO
  end

  def inner_width
    case horizontal_alignment
    when Alignment::STRETCH
      super
    else
      SIZE
    end
  end
  
  def inner_height
    case vertical_alignment
    when Alignment::STRETCH
      super
    else
      SIZE
    end
  end

  # 描画
  def draw_control(target)
    return unless (index = face_index) && (source = data(image_source))
    
    x = Itefu::Rgss3::Definition::Face.image_x(index)
    y = Itefu::Rgss3::Definition::Face.image_y(index)
    draw_bitmap(target.buffer, source, x, y, SIZE, SIZE)
  end
  
end
