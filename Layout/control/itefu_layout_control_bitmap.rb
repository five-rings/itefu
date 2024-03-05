=begin
  Layoutシステム/Bitmapデータを描画するコントロールの基底クラス
=end
class Itefu::Layout::Control::Bitmap < Itefu::Layout::Control::Base
  include Itefu::Layout::Control::Resource
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Drawable
  
  attr_bindable :image_source     # [Fixnum] リソースのID
  attr_bindable :vertical_flip    # [Boolean] 上下反転
  attr_bindable :horizontal_flip  # [Boolean] 左右反転
  attr_bindable :opacity          # [Fixnum] 不明度[0xff-0], 0xffで不透明, 0で透明

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :vertical_flip, :horizontal_flip, :opacity
      true
    when :image_source
      # AUTOでなければサイズは変わらない
      (width != Size::AUTO) && (height != Size::AUTO)
    else
      super
    end
  end

  # 描画
  def draw_control(target)
    return unless (source = data(image_source))
    draw_bitmap(target.buffer, source, source.rect.x, source.rect.y, source.rect.width, source.rect.height)
  end

private
  # Bitmapを描画する
  # @param [Rgss3::Bitmap] buffer 描画先
  # @param [Rgss3::Bitmap] source 描画するBitmap
  # @param [Fixnum] x 
  # @param [Fixnum] y 
  # @param [Fixnum] w 
  # @param [Fixnum] h 
  def draw_bitmap(buffer, source, x, y, w, h)
    base_w = content_width
    base_h = content_height
    halign = (w > base_w) ? Alignment::STRETCH : horizontal_alignment
    valign = (h > base_h) ? Alignment::STRETCH : vertical_alignment
    
    dst_rect = Itefu::Rgss3::Rect::TEMPs[0]
    src_rect = Itefu::Rgss3::Rect::TEMPs[1]
    
    case halign
    when Alignment::LEFT
      dst_rect.x = drawing_position_x
      dst_rect.width = w
    when Alignment::RIGHT
      dst_rect.x = drawing_position_x + base_w - w
      dst_rect.width = w
    when Alignment::CENTER
      dst_rect.x = drawing_position_x + (base_w - w)/2
      dst_rect.width = w
    else # strech
      dst_rect.x = drawing_position_x
      dst_rect.width = content_width
    end

    case valign
    when Alignment::TOP
      dst_rect.y = drawing_position_y
      dst_rect.height = h
    when Alignment::BOTTOM
      dst_rect.y = drawing_position_y + base_h - h
      dst_rect.height = h
    when Alignment::CENTER
      dst_rect.y = drawing_position_y + (base_h - h)/2
      dst_rect.height = h
    else # strech
      dst_rect.y = drawing_position_y
      dst_rect.height = content_height
    end
    
    if horizontal_flip
      src_rect.x = x + w
      src_rect.width = -w
    else
      src_rect.x = x
      src_rect.width = w
    end

    if vertical_flip
      src_rect.y = y + h
      src_rect.height = -h
    else
      src_rect.y = y
      src_rect.height = h
    end

    buffer.stretch_blt(dst_rect, source, src_rect, opacity || 0xff)
  end
  
end
