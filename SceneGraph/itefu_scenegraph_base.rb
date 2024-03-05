=begin  
  SceneGraphのノードの基底クラス
=end
class Itefu::SceneGraph::Base
  attr_reader :parent                   # [SceneGraph::Base] 親ノード
  attr_reader :children                 # [Array<SceneGraph::Base>] 子ノード
  attr_reader :root                     # [SceneGraph::Root] ルートノード
  attr_reader :pos_x, :pos_y            # [Fixnum] 親ノードからの相対座標
  attr_reader :screen_x, :screen_y      # [Fixnum] スクリーン座標 (自動計算される)
  attr_reader :size_w, :size_h          # [Fixnum] このノードのサイズ
  attr_reader :render_target            # [SceneGraph::RenderTarget] 描画対象
  attr_accessor :visibility             # [Boolean] このノード単体の表示設定

  def root?; false; end                 # [Boolean] グラフのルートか
  
  def alive?; @alive; end               # [Boolean] このノードが有効か
  def dead?; alive?.!; end              # [Boolean] このノードが破棄済みか

  def visible?; visibility; end         # [Boolean] このノード単体が表示状態か
  def invisible?; visible?.! end        # [Boolean] このノード単体が非表示状態か
  def shown?; @shown; end               # [Boolean] 画面に表示されているか
  def hidden?; shown?.!; end            # [Boolean] 画面に表示されていないか

  def touchable?; false; end            # [Boolean] ヒットテストの対象とするか

  def updatable?; alive?; end           # [Boolean] このノード以降の更新処理を呼ぶか
  def drawable?; alive? && shown?; end  # [Boolean] このノード以降の描画処理を呼ぶか

  # @param [SceneGraph::Base] parent 親ノード
  def initialize(parent)
    @children = []
    @alive = true
    @visibility = true
    @shown = true
    @pos_x = @pos_y = 0
    @size_w = @size_h = 0
    @screen_x = @screen_y = nil
    self.parent = parent
  end

  # 終了処理  
  def finalize
    impl_finalize if alive?
  end

  # 毎フレーム呼ぶ更新処理(独立)
  # @note 他のノードを参照しない独立した処理を行う
  def update
    impl_update if updatable?
  end

  # 毎フレーム呼ぶ更新処理(相互作用)
  # @note 他のノードとの相互作用(screen_xyを参照するなど）の処理を行う
  def update_interaction
    impl_update_interaction if updatable?
  end
  
  # 相対的な情報を絶対値に計算する
  # @note drawを呼ぶ前にactualizeする
  def update_actualization
    if alive?
      impl_update_actualization
      true
    else
      false
    end
  end

  # 毎フレーム呼ぶ描画処理
  def draw
    impl_draw if drawable?
  end

  # 新しい子ノードを作成する
  # @param [Class] klass 新しく追加するノードの型
  # @param [Array] args klassを生成する際に渡す任意の引数
  # @return [SceneGraph::Base] 新しく作成したノード
  def add_child(klass, *args, &block)
    child = klass.new(self, *args, &block)
    @children << child
    root.rebuild
    child
  end

  # 識別子つきで子ノードを追加する
  # @param [Object] id 任意の識別子
  # @param [Class] klass 新しく追加するノードの型
  # @param [Array] args klassを生成する際に渡す任意の引数
  # @return [SceneGraph::Base] 新しく作成したノード
  def add_child_with_id(id, klass, *args, &block)
    @ids ||= {}
    @ids[id] = add_child(klass, *args, &block)
  end
  alias :add_child_id :add_child_with_id

  # @return [SceneGraph::Base] 識別子をつけた子ノードを取得する
  # @param [Object] id 任意の識別子
  def child(id)
    @ids && @ids[id]
  end

  # 外部で生成したノードを子に追加する
  # @param [SceneGraph::Base] 追加したいノード
  # @return [SceneGraph::Base] 追加したノード
  # @note このノードの生存管理は生成したものが行う
  def attach(node)
    if node.parent.nil?
      @children << node
      node.attached(self)
      root.rebuild
      node
    end
  end

  # アタッチされているノードを取り除く
  # @param [SceneGraph::Base] 取り除きたいノード
  # @return [SceneGraph::Base] 取り除いたノード
  def detach(node)
    deleted = @children.delete(node)
    deleted.detached(self) if deleted
    root.rebuild
    deleted
  end

  # 自分自身を親ノードから取り除く
  # @return [SceneGraph::Base] 取り除いたノード
  def leave
    parent.detach(self)
  end
  
  # ノードを破棄する
  # @note finalizeの別名
  # @return [self] レシーバー自身を返す
  def kill
    finalize
    self
  end
  
  # 指定した位置（親ノードを基準とした相対位置）に移動する
  # @param [Fixnum] x 横座標
  # @param [Fixnum] y 縦座標
  # @return [self] レシーバー自身を返す
  def transfer(x, y)
    nullify_screen_pos
    impl_transfer(x || pos_x, y || pos_y)
    self
  end
  
  # アニメーション用のアクセッサ
  def pos_x=(x)
    transfer(x, nil)
    x
  end
  
  # アニメーション用のアクセッサ
  def pos_y=(y)
    transfer(nil, y)
    y
  end
  
  # 平行移動を行う
  # @param [Fixnum] offset_x 横方向の移動量
  # @param [Fixnum] offset_y 縦方向の移動量
  # @return [self] レシーバー自身を返す
  def move(offset_x, offset_y)
    transfer(offset_x && pos_x + offset_x, offset_y && pos_y + offset_y)
    self
  end

  # サイズを変更する  
  # @param [Fixnum] w 横幅
  # @param [Fixnum] h 高さ
  # @return [self] レシーバー自身を返す
  def resize(w, h)
    impl_resize(w || size_w, h || size_h)
    self
  end
  
  # アニメーション用のアクセッサ
  def size_w=(w)
    resize(w, nil)
    w
  end
  
  # アニメーション用のアクセッサ
  def size_h=(h)
    resize(nil, h)
    h
  end
  
  # @return [Fixnum] スクリーン座標を取得する
  def screen_x
    actualize_screen_pos_upward
    @screen_x
  end
  
  # @return [Fixnum] スクリーン座標を取得する
  def screen_y
    actualize_screen_pos_upward
    @screen_y
  end
  
  # @return [SceneGraph::Base] ヒットテストに成功したノードのインスタンス
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  def hittest(x, y)
    hit = @children.reverse_each.find {|child|
      child.hittest(x, y)
    }
    hit ||= (impl_hittest(x, y) && self)
    hit
  end
  
private
  # 終了処理
  def impl_finalize
    @ids.clear if @ids
    @children.reverse_each(&:finalize)
    @children.clear
    @alive = false
  end
  
  # 更新処理（独立）
  def impl_update
    @children.each(&:update)
  end

  # 更新処理（相互作用）
  def impl_update_interaction
    @children.each(&:update_interaction)
  end

  # 相対情報を絶対情報に計算する
  def impl_update_actualization
    actualize_screen_pos
    actualize_visibility
    @children.keep_if(&:update_actualization)
    @ids.keep_if {|k,v| v.alive? } if @ids
  end
  
  # 描画処理
  def impl_draw
    @children.each(&:draw)
  end

  # 移動処理
  def impl_transfer(x, y)
    @pos_x = x
    @pos_y = y
  end

  # サイズ変更
  def impl_resize(w, h)
    @size_w = w
    @size_h = h
  end
  
  # @return [Boolean] ヒットテストを行った成否
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  def impl_hittest(x, y)
    touchable? &&
    x >= screen_x &&
    x <= screen_x + size_w &&
    y >= screen_y &&
    y <= screen_y + size_h
  end
  
  # 親ノードを設定する
  # @param [SceneGraph::Base] node 親ノード
  def parent=(node)
    @parent = node
    if node
      actualize_root_downward
      actualize_render_target_downward
    else
      @root = nil
      @render_target = nil
      @children.each(&:actualize_root_downward)
      @children.each(&:actualize_render_target_downward)
    end
  end

public  
  # 下方向に描画対象を更新する
  # @note 子ノード全てに対しても処理する
  def actualize_render_target_downward
    @render_target = parent.render_target
    @children.each(&:actualize_render_target_downward)
  end
  
  # 下方向にルートノードを設定する
  def actualize_root_downward
    @root = parent.root
    @children.each(&:actualize_root_downward)
  end

  # 表示設定を計算する
  def actualize_visibility
    # parentが無い場合はRootに実装する
    @shown = visible? && parent.shown?
  end

  # スクリーン座標を未計算状態にする
  # @note 子ノード全てに対しても処理する
  def nullify_screen_pos
    if @screen_x || @screen_y
      @screen_x = @screen_y = nil
      @children.each(&:nullify_screen_pos)
    end
  end
  
  # スクリーン座標を計算する
  def actualize_screen_pos
    # parentが無い場合はRootに実装する
    @screen_x = parent.screen_x + pos_x
    @screen_y = parent.screen_y + pos_y
  end

  # 下方向にスクリーン座標を更新する
  # @note 子ノード全てに対しても計算する
  def actualize_screen_pos_downward
    actualize_screen_pos
    @children.each(&:actualize_screen_pos_downward)
  end

  # 上方向にスクリーン座標を更新する
  # @note 直接の親ノード全てに対しても処理する
  def actualize_screen_pos_upward
    unless @screen_x && @screen_y
      # parentが無い場合はRootに実装する
      parent.actualize_screen_pos_upward
      actualize_screen_pos
    end
  end

  # ノードを追加した際に呼ばれる
  # @param [SceneGraph::Base] parent 親ノード
  def attached(parent)
    self.parent = parent
  end

  # ノードを取り除いた際に呼ばれる
  # @param [SceneGraph::Base] ex_parent 取り除く前に親だったノード
  def detached(ex_parent)
    self.parent = nil
  end

  # @return [Array<SceneGraph::RenderTarget>] 自分以下のノードのRenderTargetを収集して返す
  def collect_render_targets
    @children.reverse_each.map(&:collect_render_targets).flatten
  end

end
