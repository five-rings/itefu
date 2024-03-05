=begin  
  SceneGraphのルート専用ノード
=end
class Itefu::SceneGraph::Root < Itefu::SceneGraph::Base
  attr_reader :render_targets         # [Array<SceneGraph::RenderTarget>] グラフ内にある描画対象
  def root?; true; end                # [Boolean] グラフのルートか
  def root; self; end

  def initialize
    super(nil)
  end

  def actualize_screen_pos
    # 親ノードを参照せずに決定する
    @screen_x = pos_x
    @screen_y = pos_y
  end

  def actualize_screen_pos_upward
    # 親ノードを参照せずに決定する
    actualize_screen_pos unless @screen_x && @screen_y
  end

  def actualize_render_target_downward
    # 親ノードを参照せずに決定する
    @children.each(&:actualize_render_target_downward)
  end

  def actualize_root_downward
    # 親ノードを参照せずに決定する
    @children.each(&:actualize_root_downward)
  end

  # 親ノードは無視される
  def parent=(node); end

  # 描画対象はむしされる
  def render_target=(node); end

  def actualize_visibility
    # 親ノードを参照せずに決定する
    @shown = visible?
  end

  def attached(parent)
    # 他のノードにアタッチすることはできない
    raise Itefu::Exception::NotSupported
  end

  def detached(ex_parent)
    # 他のノードからデタッチすることはできない
    raise Itefu::Exception::NotSupported
  end

  # ツリー情報を構築しなおす
  def rebuild
    # 無効にしておいて必要になってから生成する
    @render_targets = nil
  end
  
  # レンダーターゲットを収集する
  def actualize_render_target
    @render_targets ||= collect_render_targets.
                          sort_by.
                          with_index {|target, i| target.comparison_value(i) }
  end

  # @return [SceneGraph::Base] ヒットテストに成功したノードのインスタンス
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  # @note 描画順序を考慮して最前面にあるものから順に評価する
  def hittest(x, y)
    actualize_render_target

    # 描画順の逆(画面の手前から)順にヒットテストを行う
    @render_targets.reverse_each do |target|
      if node = target.hittest(x, y)
        return node 
      end
    end
    # ヒットテストに成功したノードはなかった
    nil
  end
  
  # Spriteを子ノードとして追加する
  def add_sprite(*args, &block)
    add_child(Itefu::SceneGraph::Sprite, *args, &block)
  end
 
  # 識別子つきでSpriteを子ノードとして追加する
  def add_sprite_id(id, *args, &block)
    add_child_id(id, Itefu::SceneGraph::Sprite, *args, &block)
  end
  
end
