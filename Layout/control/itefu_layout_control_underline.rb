=begin
  Layoutシステム/下線を引きたいコントロールにmix-inする
  paddingとmarginの境界に線を引く
=end
module Itefu::Layout::Control::Underline
  extend Itefu::Layout::Control::Bindable::Extension
  include Itefu::Layout::Control::Drawable
  attr_bindable :underline        # [Color] 下線の色
  attr_bindable :underline_offset # [Fixnum] 下線を上下にずらす
  attr_bindable :underline_size   # [Fixnum] 下線のサイズ
  attr_bindable :fill_padding # [Boolean] padding領域を塗りつぶすか

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :underline, :underline_size
      true
    else
      super
    end
  end

  # 再描画不要の条件
  def stable_in_appearance?(name)
    super
  end

  def draw_control(target)
    if color = self.underline
      offset = self.underline_offset || 0
      size = self.underline_size || 1

      if self.fill_padding
        x = drawing_position_x - padding.left
        y = drawing_position_y - padding.top
        w = actual_width
        h = actual_height
      else
        x = drawing_position_x
        y = drawing_position_y
        w = content_width
        h = content_height
      end

      bitmap = target.buffer
      bitmap.fill_rect(x, y+h+offset, w, size, color)
    end

    super
  end

end
