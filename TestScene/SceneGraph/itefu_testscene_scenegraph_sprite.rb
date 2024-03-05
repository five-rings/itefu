=begin
  SceneGraphのテスト用のScene
  Spriteの機能を確認する
=end
class Itefu::TestScene::SceneGraph::Sprite < Itefu::Scene::Base
  include Itefu::Resource::Container
  
  class TestFiller < Itefu::SceneGraph::Node
    def on_initialize(color)
      @color = color
    end

    def on_draw(target)
      target.buffer.fill_rect(target.relative_pos_x(self), target.relative_pos_y(self), size_w, size_h, @color)
    end
  end

  class TestNode < TestFiller
    def on_initialized(*args)
      @value = 1
    end

    def on_update
      move(@value, 0)
      render_target.move(0, -@value)
      @value *= -1 if pos_x >= 100 || pos_x <= 0
    end
  end
  
  class TestRolling < TestFiller
    def on_update
      parent.sprite.angle = (parent.sprite.angle + 10) % 360
    end
  end
  
  class TestZooming < TestFiller
    def on_initialized(*args)
      @value = 0.1
    end

    def on_update
      parent.sprite.zoom_x -= @value
      parent.sprite.zoom_y -= @value
      @value *= -1 if parent.sprite.zoom_x <= 0.1 || parent.sprite.zoom_x >= 2.0
    end
  end

  def on_initialize
    @scenegraph = create_resource(Itefu::SceneGraph::Root).transfer(320, 240)

    # 横線
    @scenegraph.add_child(Itefu::SceneGraph::Sprite, 256, 1).transfer(-128, 0).tap {|node|
                  node.sprite.z = 1
                  node.anchor(0.5, 128)
                }.
                add_child(TestFiller, Itefu::Color.Blue).resize(256, 1)
    # 縦線
    @scenegraph.add_child(Itefu::SceneGraph::Sprite, 1, 256).transfer(0, -128).tap {|node|
                  node.sprite.z = 1
                  node.anchor(0.5, 1.0)
                }.
                add_child(TestFiller, Itefu::Color.Blue).resize(1, 256)
    
    # テスト描画
    @scenegraph.add_child(Itefu::SceneGraph::Sprite, 128, 128).tap {|node|
                  node.sprite.z = 1
                  node.sprite.wave_amp = 4
                  node.sprite.wave_length = 128
                  node.sprite.wave_speed = 360
                  node.transfer(nil, 10)
                  node.anchor(0.5, 1.0)
                  node.offset(-0.5, -1.0)
                }.
                add_child(TestFiller, Itefu::Color.Red).resize(128, 128).
                # Spriteの中身だけ書き換わるノード
                add_child(TestNode, Itefu::Color.Black).resize(8, 8).transfer(10, 10).
                # Spriteの子ノードに追従する別のSprite
                add_child(Itefu::SceneGraph::Sprite, 16, 16).
                add_child(TestFiller, Itefu::Color.Blue).resize(16, 16)

    # 回転
    @scenegraph.add_child(Itefu::SceneGraph::Sprite, 16, 16).tap {|node|
                  node.sprite.z = 1
                  node.anchor(0.5, 2.0)
                  node.transfer(-8, 10)
                }.
                add_child(TestRolling, Itefu::Color.White).resize(16, 16)

    # 拡大縮小
    @scenegraph.add_child(Itefu::SceneGraph::Sprite, 32, 32,).tap {|node|
      node.sprite.z = 1
      node.anchor(0.5, 1.0)
      node.transfer(-16, -32+10)
      node.add_child(TestFiller, Itefu::Color.Green).resize(32, 32)
      node.add_child(TestZooming, Itefu::Color.Black).resize(8, 8).transfer(12, 12)
    }
  end

  def on_finalize
    finalize_all_resources
  end

  def on_update
    case
    when Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_ESCAPE),
         Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_RBUTTON)
      quit
    end

    @scenegraph.update
    @scenegraph.update_interaction
    @scenegraph.update_actualization
  end
  
  def on_draw
    @scenegraph.draw
  end

end
