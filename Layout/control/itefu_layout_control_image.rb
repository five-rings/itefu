=begin
  Layoutシステム/画像を描画するコントロール
=end
class Itefu::Layout::Control::Image < Itefu::Layout::Control::Bitmap
  attr_bindable :source_rect    # [Layout::Definition::Rect] リソースの矩形 

  def default_horizontal_alignment; Alignment::STRETCH; end
  def default_vertical_alignment;   Alignment::STRETCH; end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :image_source
      # AUTOでなければ画像がかわってもサイズはかわらない
      # AUTOであっても, source_rectが設定されていればそのサイズになるので, 画像が変わってもサイズは変わらない
      (width != Size::AUTO) && (height != Size::AUTO) || source_rect
    when :source_rect
      # AUTOでなければサイズは変わらない
      (width != Size::AUTO) && (height != Size::AUTO)
    else
      super
    end
  end

  # 計測
  def impl_measure(available_width, available_height)
    src = data(image_source)
    if (rect = source_rect)
      # 矩形が指定されている場合は, そのサイズを画像サイズとして扱う
      @desired_width  = padding.width  + Size.to_actual_value(rect.width,  src && src.rect.width || 0)  if width == Size::AUTO
      @desired_height = padding.height + Size.to_actual_value(rect.height, src && src.rect.height || 0) if height == Size::AUTO
    elsif src
      # サイズが指定されていなければ, 画像のサイズをそのまま使う
      @desired_width  = padding.width  + src.rect.width  if width == Size::AUTO
      @desired_height = padding.height + src.rect.height if height == Size::AUTO
    end
  end

  def inner_width
    case horizontal_alignment
    when Alignment::STRETCH
      super
    else
      if (source = data(image_source)).nil?
        super
      elsif (rect = source_rect)
        Size.to_actual_value(rect.width,  source.rect.width)
      else
        source.rect.width
      end
    end
  end
  
  def inner_height
    case vertical_alignment
    when Alignment::STRETCH
      super
    else
      if (source = data(image_source)).nil?
        super
      elsif (rect = source_rect)
        Size.to_actual_value(rect.height,  source.rect.height)
      else
        source.rect.height
      end
    end
  end

  # 描画
  def draw_control(target)
    if (rect = source_rect)
      return unless (source = data(image_source))
      # source_rectで指定された範囲を描画する
      x = Size.to_actual_value(rect.x,      source.rect.width)
      w = Size.to_actual_value(rect.width,  source.rect.width)
      y = Size.to_actual_value(rect.y,      source.rect.height)
      h = Size.to_actual_value(rect.height, source.rect.height)
      draw_bitmap(target.buffer, source, x, y, w, h)
    else
      # 全体を描画する
      super
    end
  end
  
end
