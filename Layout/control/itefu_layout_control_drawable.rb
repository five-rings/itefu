=begin
  Layoutシステム/描画処理を実装するためのインターフェイス
=end
module Itefu::Layout::Control::Drawable
  include Itefu::Layout::Control::DrawControl
  extend Itefu::Layout::Control::Bindable::Extension
  attr_bindable :independent


  # @return [Fixnum] RenderTargetのbuffer上の横座標
  def drawing_position_x
    screen_x - render_target.drawing_offset_x + padding.left
  end
  
  # @return [Fixnum] RenderTargetのbuffer上の縦座標
  def drawing_position_y
    screen_y - render_target.drawing_offset_y + padding.top
  end

  # 描画
  def impl_draw
    return super unless (target = render_target) && (buffer = target.buffer)

    if target.corrupted?
      # バッファ全体を描画しなおしている
      super
      @dirty_rect = false
    elsif @dirty_rect
      # このコントロールのみ更新する
      clear_dirty_rect(target)
      super
      @dirty_rect = false
    else
      # 再描画の必要なし
      super
    end
  end

  # コントロールの占有している矩形をクリアする  
  def clear_dirty_rect(target)
    target.buffer.clear_rect(drawing_position_x, drawing_position_y, actual_width, actual_height)
  end
  
  # 再描画の必要があるか
  def draw_control_corrupted?
    @dirty_rect ||
    (target = render_target) && target.corrupted?
  end

  # 再描画が必要な状態にする
  def corrupt
    if independent
      @dirty_rect = true
    else
      super
    end
  end

end
