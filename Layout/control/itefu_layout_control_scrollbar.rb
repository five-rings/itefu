=begin
  Layoutシステム/スクロールバーを表示する
=end
module Itefu::Layout::Control::ScrollBar
  include Itefu::Layout::Definition
#ifdef :ITEFU_DEVELOP
  extend Utility::Module.expect_for(Itefu::Layout::Control::Scrollable)
#endif

  DEFAULT_SMALLEST_BAR_SIZE = 5

  # 描画
  def draw_control(target)
    if target && target.buffer
      draw_scroll_bar(target.buffer)
    end
    super
  end
  
private

  # スクロールバーのバーの部分を描画する
  # @note デフォルト兼サンプルとして実装しているので、必要に応じてオーバーライドする
  # @param [Itefu::Rgss3::Bitmap] 描画先のバッファ
  # @param [Float] hor 横方向のバーの位置
  # @param [Float] ver 縦方向のバーの位置
  # @param [Float|NilClass] 横サイズ
  # @param [Float|NilClass] 縦サイズ
  # @note 縦横サイズは、スクロールしない方向はnil, スクロール方向には スクロールする幅全体に対する画面の比率に応じたサイズ が渡される
  def draw_scroll_bar_content(buffer, hor, ver, w, h)
    w = w && Utility::Math.max(DEFAULT_SMALLEST_BAR_SIZE, w) || DEFAULT_SMALLEST_BAR_SIZE 
    h = h && Utility::Math.max(DEFAULT_SMALLEST_BAR_SIZE, h) || DEFAULT_SMALLEST_BAR_SIZE 
    x = drawing_position_x - padding.left + (actual_width  - w) * hor
    y = drawing_position_y - padding.top  + (actual_height - h) * ver
    buffer.fill_rect(x, y, w, h, Itefu::Color.White)
  end

  # スクロールバーを描画する
  def draw_scroll_bar(buffer)
    case scroll_direction
    when Orientation::VERTICAL
      # 左右にスクロールバーを出す
      draw_vertical_scroll_bar(buffer)
    when Orientation::HORIZONTAL
      # 上下にスクロールバーを出す
      draw_horizontal_scroll_bar(buffer)
    else
      # 上下左右にスクロールバーを出す
      draw_vertical_scroll_bar(buffer)
      draw_horizontal_scroll_bar(buffer)
    end
  end
  
  # 横方向に動くスクロールバーを描画する
  def draw_horizontal_scroll_bar(buffer)
    min = scroll_x_min
    max = scroll_x_max
    return unless min && max
    dif = max - min
    return unless dif > 0

    sx = scroll_x || 0
    pos = (sx - min) / (max - min).to_f
    size = content_width ** 2 / (dif + content_width).to_f
    draw_scroll_bar_content(buffer, pos, 1.0, size, nil)
  end

  # 縦方向に動くスクロールバーを描画する
  def draw_vertical_scroll_bar(buffer)
    min = scroll_y_min
    max = scroll_y_max
    return unless min && max
    dif = max - min
    return unless dif > 0

    sy = scroll_y || 0
    pos = (sy - min) / (max - min).to_f
    size = content_height ** 2 / (dif + content_height).to_f
    draw_scroll_bar_content(buffer, 1.0, pos, nil, size)
  end
  
end
