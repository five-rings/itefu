=begin
  Layoutシステム/Drawable/RenderTargetで共通のコントロール描画インターフェイス
=end
module Itefu::Layout::Control::DrawControl

  # コントロールの描画処理
  def draw_control(target); end

  # @return [Boolean] 再描画の必要があるか
  def draw_control_corrupted?; raise Itefu::Layout::Definition::Exception::NotImplemented; end

  # render_target
  # Control::Base/RenderTargetで実装されていることを前提にしている
  
  # 描画
  def impl_draw
    if draw_control_corrupted?
      execute_callback(:draw_control)
      draw_control(render_target)
      super
      execute_callback(:drawn_control)
    else
      super
    end
  end

end
