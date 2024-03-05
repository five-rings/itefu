=begin
  Layoutシステム/テキスト表示を行うコントロール
=end
class Itefu::Layout::Control::Label < Itefu::Layout::Control::Base
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Drawable
  include Itefu::Layout::Control::Font
  attr_bindable :text     # [String] ラベルに表示する文字列

  # フォントが変更された際の処理
  def font_changed(name, attribute)
    super
    @text_rect = nil
  end

  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :text
      @text_rect = nil
    end
    super
  end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :text
      # サイズが指定されているなら文字がかわっても変更されない
      (width != Size::AUTO) && (height != Size::AUTO)
    else
      super
    end
  end
  
  # 計測
  def impl_measure(available_width, available_height)
    update_text_rect
    if @text_rect
      @desired_width  = padding.width  + @text_rect.width   if width  == Size::AUTO
      @desired_height = padding.height + @text_rect.height  if height == Size::AUTO
    end
  end
  
  def inner_width
    if @text_rect
      @text_rect.width
    else
      super
    end
  end
  
  def inner_height
    if @text_rect
      @text_rect.height
    else
      super
    end
  end
 
  # 描画 
  def impl_draw
    # サイズ固定のコントロールでテキストが変更されたときなど、rearrangeがかからずにtext_rectが無効になった場合に備えて呼ぶ
    update_text_rect
    super
  end
 
  # テキスト描画
  def draw_control(target)
    use_bitmap_applying_font(target.buffer, font) do |buffer|
      text_height = @text_rect && @text_rect.height || content_height
      x = drawing_position_x
      y = drawing_position_y

      case vertical_alignment
      when Alignment::TOP
        buffer.draw_text(x, y, content_width, text_height, text, text_horizontal_alignment)
      when Alignment::BOTTOM
        buffer.draw_text(x, y + content_height - text_height, content_width, text_height, text, text_horizontal_alignment)
      else  # center, stretch
        buffer.draw_text(x, y, content_width, content_height, text, text_horizontal_alignment)
      end
    end
  end

private

  # 文字列描画に必要な矩形を計算する
  def update_text_rect
    return if @text_rect
    use_bitmap_applying_font(Itefu::Rgss3::Bitmap.empty, font) do |buffer|
      t = text.to_s
      @text_rect = buffer.rich_text_size(t)
      @text_rect.height = buffer.font.size if t.empty?
    end
  end

end
