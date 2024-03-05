=begin
  SceneGraphのテスト用のScene
  ヒットテスト（マウスクリック）の確認をする
=end
class Itefu::TestScene::SceneGraph::HitTest < Itefu::Scene::Base
  include Itefu::Resource::Container

  class TestFiller < Itefu::SceneGraph::Node
    include Itefu::SceneGraph::Touchable
    include Itefu::Animation::Player

    def on_initialized(name, color)
      @name = name
      @color = color
      @anime = Itefu::Animation::Battler.new
      @anime.effect_type = Itefu::Animation::Battler::EffectType::COLLAPSE
      @anime.finished = method(:effect_finished)
    end

    def effect_finished(anime)
      render_target.visibility = anime.sprite.visible unless anime.sprite.disposed?
    end
    
    def on_finalize
      finalize_animations
      @anime.finalize
      @anime = nil
    end

    def on_update
      if @touching
        render_target.sprite.angle = (render_target.sprite.angle + 10) % 360
      end
    end
    
    def on_updated_actualization
      update_animations
    end

    def on_draw(target)
      target.buffer.fill_rect(target.relative_pos_x(self), target.relative_pos_y(self), size_w, size_h, @color)
    end
    
    def on_touched(x, y, kind)
      @touching = true
      @anime.sprite = render_target.sprite
      play_animation(:battler, @anime)
    end
    
    def on_untouched(kind)
      @touching = nil
    end
  end

  def on_initialize
    @scenegraph = create_resource(Itefu::SceneGraph::Root)
    
    # 作成順序
    @scenegraph.add_sprite(32, 32).transfer(50, 50).anchor(0.5, 0.5).
                add_child(TestFiller, "Red", Itefu::Color.Red).resize(32, 32)
    @scenegraph.add_sprite(32, 32).transfer(60, 60).anchor(0.5, 0.5).
                add_child(TestFiller, "Blue", Itefu::Color.Blue).resize(32, 32)

    # Viewportなしでz指定
    @scenegraph.add_sprite(32, 32).transfer(150, 50).anchor(0.5, 0.5).tap {|node|
                  node.sprite.z = 1
                }.
                add_child(TestFiller, "Red", Itefu::Color.Red).resize(32, 32)
    @scenegraph.add_sprite(32, 32).transfer(160, 60).anchor(0.5, 0.5).tap {|node|
                  node.sprite.z = 0
                }.
                add_child(TestFiller, "Blue", Itefu::Color.Blue).resize(32, 32)

    # Viewportを設定
    @scenegraph.add_sprite(32, 32).transfer(250, 50).anchor(0.5, 0.5).tap {|node|
                  node.sprite.z = 0
                  Itefu::Rgss3::Viewport.new.auto_release do |vp|
                    vp.z = 1
                    node.sprite.viewport = vp
                  end
                }.
                add_child(TestFiller, "Red", Itefu::Color.Red).resize(32, 32)
    @scenegraph.add_sprite(32, 32).transfer(260, 60).anchor(0.5, 0.5).tap {|node|
                  node.sprite.z = 1
                  Itefu::Rgss3::Viewport.new.auto_release do |vp|
                    vp.z = 0
                    node.sprite.viewport = vp
                  end
                }.
                add_child(TestFiller, "Blue", Itefu::Color.Blue).resize(32, 32)

    # yが大きい方を優先
    @scenegraph.add_sprite(32, 32).transfer(350, 60).anchor(0.5, 0.5).
                add_child(TestFiller, "Red", Itefu::Color.Red).resize(32, 32)
    @scenegraph.add_sprite(32, 32).transfer(360, 50).anchor(0.5, 0.5).
                add_child(TestFiller, "Blue", Itefu::Color.Blue).resize(32, 32)
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

    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_LBUTTON)
      if @pressed
        @pressed.touching(nil, nil)
      elsif @pressed.nil?
        x, y = Itefu::Input::Win32.position
        @pressed = @scenegraph.hittest(x, y) || false
        @pressed.touched(x,y) if @pressed
      end
    else
      @pressed.untouched if @pressed
      @pressed = nil unless @pressed.nil?
    end

    @scenegraph.update
    @scenegraph.update_interaction
    @scenegraph.update_actualization
  end
  
  def on_draw
    @scenegraph.draw
  end

end
