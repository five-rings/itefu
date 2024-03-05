=begin  
  描画対象  
  SceneGraphで各ノードが描画を行う対象
=end
module Itefu::SceneGraph::RenderTarget

  # @return [Rgss3::Bitmap] 描画可能なビットマップオブジェクト
  def buffer; raise Itefu::Exception::NotImplemented; end
  
  # @return [Rgss3::Viewport] 割り当てられたViewport
  def viewport; raise Itefu::Exception::NotImplemented; end
  
  # @return [Comparable] 描画順序を比較するための値を返す
  def comparison_value(index); raise Itefu::Exception::NotImplemented; end

  # 再描画の必要があるか
  def corrupted?; @corrupted; end
  
  # 再描画が必要な状態にする
  def be_corrupted; @corrupted = true; end
  
  # 再描画が必要な状態を解消する
  def resolve_corruption; @corrupted = false; end
  
  # レンダーターゲットは自分自身になる
  def render_target; self; end
  
  # 親階層の別のレンダーターゲット
  def parent_render_target; @render_target; end

  # 子ノードのrender_targetは自分自身のままなので, 子ノードは更新しない
  def actualize_render_target_downward
    @render_target = parent.render_target
  end

  # @return [Array<SceneGraph::RenderTarget>] 自分以下のノードのRenderTargetに自分を加えて返す
  def collect_render_targets
    super << self
  end

  # render_targetに描画されていた内容をクリアする
  def clear_render_target(bitmap)
    bitmap.clear
  end

private

  def impl_draw
    # 再描画が必要なら、描画処理の前に、バッファをクリアする
    if corrupted?
      bitmap = buffer
      clear_render_target(bitmap) if bitmap
      super
      resolve_corruption
    else
      super
    end
  end

end
