=begin
  Layoutシステム/仕切り線を描画するコントロール
=end
class Itefu::Layout::Control::Separator < Itefu::Layout::Control::Base
  include Itefu::Layout::Control::Drawable
  attr_bindable :separate_color   # [Color] 仕切り線の色
  attr_bindable :border_color     # [Color] 仕切り線の枠の色

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :separator_color, :border_color
      # 色を変えても配置は変わらない
      true
    else
      super
    end
  end

  # 描画
  def draw_control(target)
    sc = separate_color
    bc = border_color
    x = drawing_position_x
    y = drawing_position_y
    
    target.buffer.fill_rect(x-padding.left, y-padding.top, actual_width, actual_height, bc) if bc
    target.buffer.fill_rect(x, y, content_width, content_height, sc) if sc
  end

end