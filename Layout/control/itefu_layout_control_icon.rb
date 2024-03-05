=begin
  Layoutシステム/アイコンを描画するコントロール
=end
class Itefu::Layout::Control::Icon < Itefu::Layout::Control::Bitmap
  attr_bindable :icon_index     # [Fixnum] アトラス上のアイコンindex

  # アイコンアトラス上の1アイコンのサイズ
  SIZE = Itefu::Rgss3::Definition::Icon::SIZE

  def initialize(parent)
    super
    # アイコン画像は固有なので読み込んでおく
    self.image_source = load_image(Itefu::Rgss3::Filename::Graphics::ICONSET)
  end
  
  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :image_source, :icon_index
      # どの画像, どのアイコンでもサイズには影響しない
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
    return unless (index = icon_index) && (source = data(image_source))

    x = Itefu::Rgss3::Definition::Icon.image_x(index)
    y = Itefu::Rgss3::Definition::Icon.image_y(index)
    draw_bitmap(target.buffer, source, x, y, SIZE, SIZE)
  end
end
