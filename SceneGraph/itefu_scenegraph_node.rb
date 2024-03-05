=begin  
  ユーザ独自のSceneGraphのノードを作る用の基底クラス
=end
class Itefu::SceneGraph::Node < Itefu::SceneGraph::Base

  # 初期前に呼ばれる
  def on_initialize(*args, &block); end

  # 初期化後に呼ばれる
  def on_initialized(*args, &block); end

  # 終了直前に呼ばれる
  def on_finalize; end

  # 終了直後に呼ばれる
  def on_finalized; end

  # 毎フレーム呼ばれる更新処理
  # @note 子ノードの処理の前に呼ばれる
  def on_update; end

  # 毎フレーム呼ばれる更新処理
  # @note 子ノードの処理の後に呼ばれる
  def on_updated; end

  # 毎フレーム呼ばれる更新処理(相互作用)
  # @note 子ノードの処理の前に呼ばれる
  def on_update_interaction; end

  # 毎フレーム呼ばれる更新処理(相互作用)
  # @note 子ノードの処理の後に呼ばれる
  def on_updated_interaction; end

  # 相対情報を絶対情報に計算する
  # @note 子ノードの処理の前に呼ばれる
  def on_update_actualization; end

  # 相対情報を絶対情報に計算する
  # @note 子ノードの処理の後に呼ばれる
  def on_updated_actualization; end

  # 毎フレーム呼ばれる描画処理
  # @note 子ノードの処理の前に呼ばれる
  # @param [SceneGraph::RenderTarget] target 描画対象
  def on_draw(target); end

  # 毎フレーム呼ばれる描画処理
  # @note 子ノードの処理の後に呼ばれる
  # @param [SceneGraph::RenderTarget] target 描画対象
  def on_drawn(target); end

  # 移動処理の前に呼ばれる
  # @param [Fixnum] x 移動先の横座標
  # @param [Fixnum] x 移動先の縦座標
  def on_transfer(x, y); end

  # 移動処理の後に呼ばれる
  # @param [Fixnum] x 移動先の横座標
  # @param [Fixnum] x 移動先の縦座標
  def on_transfered(x, y); end

  # サイズ変更前に呼ばれる
  # @param [Fixnum] w 新しい横幅
  # @param [Fixnum] h 新しい高さ
  def on_resize(w, h); end

  # サイズ変更後に呼ばれる
  # @param [Fixnum] w 新しい横幅
  # @param [Fixnum] h 新しい高さ
  def on_resized(w, h); end

  # 他のノードの子として追加された際に呼ばれる
  # @param [SceneGraph::Base] parent 新しい親ノード
  def on_attached(parent); end

  # 他のノードから取り外された際に呼ばれる
  # @param [SceneGraph::Base] parent 新しい親ノード
  def on_detached(ex_parent); end

private
  def initialize(parent, *args, &block)
    on_initialize(*args, &block)
    super(parent)
    on_initialized(*args, &block)
  end

  def impl_finalize
    on_finalize
    super
    on_finalized
  end

  def impl_update
    on_update
    super
    on_updated
  end
  
  def impl_update_interaction
    on_update_interaction
    super
    on_updated_interaction
  end
  
  def impl_update_actualization
    on_update_actualization
    super
    on_updated_actualization
  end

  def impl_draw
    # 再描画が必要な場合のみon_draw/on_drawnを呼ぶ
    return super unless (target = render_target) && (buffer = target.buffer)

    if target.corrupted?
      # バッファ全体を描画しなおしている
      on_draw(target)
      super
      on_drawn(target)
      @dirty_rect = nil
    elsif @dirty_rect
      # このノードのみ更新する
      clear_dirty_rect(target)
      on_draw(target)
      super
      on_drawn(target)
      @dirty_rect = nil
    else
      # 再描画の必要なし
      super
    end
  end
  
  def impl_transfer(x, y)
    on_transfer(x, y)
    super
    # 描画位置が変わるので再描画を要求する
    corrupt(render_target)
    on_transfered(x, y)
  end
  
  def impl_resize(w, h)
    on_resize(w, h)
    super
    # 描画範囲が変わるので再描画を要求する
    corrupt(render_target)
    on_resized(w, h)
  end
  
  # @param [SceneGraph::RenderTarget | SceneGraph::Node] target 再描画が必要な状態にする対象
  def corrupt(target)
    target.be_corrupted if target
  end

  # バッファの一部分だけをクリアする
  # @param [SceneGraph::Base] target 描画対象
  def clear_dirty_rect(target)
    target.buffer.clear_rect(target.relative_pos_x(self), target.relative_pos_y(self), size_w, size_h)
  end

public
  # 自ノードの範囲のみの再描画を要求する
  def be_corrupted
    @dirty_rect = self
  end

  def attached(parent)
    super
    # 新しく描画するものが増えるので再描画を要求する
    corrupt(render_target)
    on_attached(parent)
  end

  def detached(ex_parent)
    super
    # 取り外した分を消したいので再描画を要求する
    corrupt(render_target)
    on_detached(ex_parent)
  end

end
