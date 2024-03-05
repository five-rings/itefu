=begin
  SceneGraphのテストコード
=end
class Itefu::Test::SceneGraph < Itefu::UnitTest::TestCase

  class TestNode < Itefu::SceneGraph::Node
    attr_reader :data
    def clear; data.clear; end

    def on_initialize; @data = [:initialize]; end
    def on_initialized; @data.push :initialized; end
    def on_finalize; @data.push :finalize; end
    def on_finalized; @data.push :finalized; end
    def on_update; @data.push :update; end
    def on_updated; @data.push :updated; end
    def on_update_interaction; @data.push :update_interaction; end
    def on_updated_interaction; @data.push :updated_interaction; end
    def on_draw(target); @data.push :draw; end
    def on_drawn(target); @data.push :drawn; end

    def on_transfer(x, y); @data.push :transfer; end
    def on_transfered(x, y); @data.push :transfered; end
    def on_resize(w, h); @data.push :resize; end
    def on_resized(w, h); @data.push :resized; end
    def on_attached(parent); @data.push :attached; end
    def on_detached(ex_parent); @data.push :detached; end
  end

  def test_update
    root = Itefu::SceneGraph::Root.new
    test_sprite = root.add_child(Itefu::SceneGraph::Sprite, 32, 48)
    test_node = test_sprite.add_child(TestNode)
    
    # ノードの追加と初期化を確認
    assert_instance_of(TestNode, test_node)
    assert_equal([:initialize, :initialized], test_node.data)

    # transfer
    test_node.clear
    test_node.transfer(10, 20)
    assert_equal([:transfer, :transfered], test_node.data)
    assert_equal(10, test_node.pos_x)
    assert_equal(20, test_node.pos_y)
    
    # transfer parent
    test_sprite.transfer(100, 200)
    assert_equal(100, test_sprite.pos_x)
    assert_equal(200, test_sprite.pos_y)

    # resize
    test_node.clear
    test_node.resize(40, 50)
    assert_equal([:resize, :resized], test_node.data)
    assert_equal(40, test_node.size_w)
    assert_equal(50, test_node.size_h)

    # update
    test_node.clear
    root.update
    assert_equal([:update, :updated], test_node.data)

    # update_interaction    
    test_node.clear
    root.update_interaction
    assert_equal([:update_interaction, :updated_interaction], test_node.data)

    # screen_xy
    assert_equal(110, test_node.screen_x)
    assert_equal(220, test_node.screen_y)

    # draw
    test_node.clear
    root.draw
    assert_equal([:draw, :drawn], test_node.data)

    # corruptedが解消されたので呼ばれない
    test_node.clear
    root.draw
    assert_equal([], test_node.data)

    # 部分的に更新する
    test_node.clear
    test_node.be_corrupted
    root.draw
    assert_equal([:draw, :drawn], test_node.data)

    # visibility
    # invisibleなので呼ばれない
    test_node.clear
    test_node.be_corrupted
    test_node.visibility = false
    root.update_actualization
    root.draw
    assert_equal([], test_node.data)

    # 表示に戻したので呼ばれる
    test_node.clear
    test_node.be_corrupted
    test_node.visibility = true
    root.update_actualization
    root.draw
    assert_equal([:draw, :drawn], test_node.data)

    # 親ノードが非表示なので呼ばれない
    test_node.clear
    test_sprite.visibility = false
    test_sprite.be_corrupted
    root.update_actualization
    root.draw
    assert_equal([], test_node.data)

    # 親ノードが表示に戻したので呼ばれる
    test_node.clear
    test_sprite.visibility = true
    root.update_actualization
    root.draw
    assert_equal([:draw, :drawn], test_node.data)

    # detach
    test_node.clear
    assert_same(test_node, test_node.leave)
    assert_equal([:detached], test_node.data)

    # detachされていることの確認
    test_node.clear
    root.update
    assert_equal([], test_node.data)

    # attach
    test_node.clear
    assert_same(test_node, root.attach(test_node))
    root.update
    assert_equal([:attached, :update, :updated], test_node.data)

    # render_targetがないのでdrawが呼ばれないことの確認
    test_node.clear
    root.draw
    assert_equal([], test_node.data)

    # kill
    test_node.clear
    test_node.kill
    assert_equal([:finalize, :finalized], test_node.data)

    # kill済みのノードが取り除かれるのを確認
    test_node.clear
    root.update_actualization
    root.update
    assert_equal([], test_node.data)
  end
  
  def test_root
    root1 = Itefu::SceneGraph::Root.new
    assert_raises(ArgumentError) do
      root1.add_child(Itefu::SceneGraph::Root)
    end

    root2 = Itefu::SceneGraph::Root.new
    assert_raises(Itefu::Exception::NotSupported) do
      root1.attach(root2)
    end
    
    node1 = root1.add_child(Itefu::SceneGraph::Node)
    assert_same(root1, node1.root)
    node2 = node1.add_child(Itefu::SceneGraph::Node)
    assert_same(root1, node2.root)
    
    assert_same(node1, root1.detach(node1))
    assert_nil(node1.root)
    assert_nil(node2.root)
    
    assert_same(node1, root2.attach(node1))
    assert_same(root2, node1.root)
    assert_same(root2, node2.root)
  end
  
  def test_sprite
    bitmap = Itefu::Rgss3::Bitmap.new(64, 64)
    root = Itefu::SceneGraph::Root.new
    test_sprite1 = root.add_child(Itefu::SceneGraph::Sprite, 16, 32)
    test_sprite2 = test_sprite1.add_child(Itefu::SceneGraph::Node).add_child(Itefu::SceneGraph::Sprite, 24, 48, bitmap, 11, 12)

    # サイズのチェック
    assert_equal(16, test_sprite1.size_w)
    assert_equal(32, test_sprite1.size_h)
    assert_equal(24, test_sprite2.size_w)
    assert_equal(48, test_sprite2.size_h)
    assert_equal(Rect.new(0, 0, 16, 32), test_sprite1.sprite.src_rect)
    assert_equal(Rect.new(11, 12, 24, 48), test_sprite2.sprite.src_rect)

    # バッファ作成した場合のリサイズ
    bmp1 = test_sprite1.buffer
    test_sprite1.resize(8, 16)
    bmp2 = test_sprite1.buffer
    assert_equal( 8, test_sprite1.size_w)
    assert_equal(16, test_sprite1.size_h)
    assert_not_same(bmp1, bmp2)
    assert_equal(Rect.new(0, 0, 8, 16), test_sprite1.sprite.src_rect)
    
    # テクスチャ割り当ての場合のリサイズ
    test_sprite2.resize(4, 8)
    assert_equal(4, test_sprite2.size_w)
    assert_equal(8, test_sprite2.size_h)
    assert_nil(test_sprite2.buffer)   # 外部割り当ての場合はnilになる
    assert_equal(Rect.new(11, 12, 4, 8), test_sprite2.sprite.src_rect)

    # transfer
    test_sprite1.transfer(11, 22)
    test_sprite2.transfer(100, 200)
    root.update_actualization
    assert_equal(11, test_sprite1.sprite.x)
    assert_equal(22, test_sprite1.sprite.y)
    assert_equal(111, test_sprite2.sprite.x)
    assert_equal(222, test_sprite2.sprite.y)

    # anchor
    test_sprite2.anchor(0.5, 3)
    root.update_actualization
    assert_equal(2, test_sprite2.sprite.ox)
    assert_equal(3, test_sprite2.sprite.oy)
    assert_equal(113, test_sprite2.sprite.x)
    assert_equal(225, test_sprite2.sprite.y)

    # offset
    test_sprite2.offset(50, 60)
    root.update_actualization
    assert_equal(163, test_sprite2.sprite.x)
    assert_equal(285, test_sprite2.sprite.y)

    # visibility
    test_sprite2.visibility = false
    root.update_actualization
    assert(test_sprite2.shown?.!)
    assert(test_sprite2.sprite.visible.!)
    test_sprite2.visibility = true
    root.update_actualization
    assert(test_sprite2.shown?)
    assert(test_sprite2.sprite.visible)
    test_sprite1.visibility = false
    root.update_actualization
    assert(test_sprite1.shown?.!)
    assert(test_sprite2.shown?.!)
    assert(test_sprite1.sprite.visible.!)
    assert(test_sprite2.sprite.visible.!)
  end

end
