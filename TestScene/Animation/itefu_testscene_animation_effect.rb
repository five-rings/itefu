=begin
  Animationのテスト用のScene
=end
class Itefu::TestScene::Animation::Effect < Itefu::Scene::Base
  include Itefu::Animation::Player
  include Itefu::Resource::Container

  class TestFiller < Itefu::SceneGraph::Node
    include Itefu::SceneGraph::Touchable
    def on_draw(target)
      target.buffer.fill_rect(target.relative_pos_x(self), target.relative_pos_y(self), size_w, size_h, Itefu::Color.Red)
    end
  end

  def on_initialize
    @as = load_data(Itefu::Rgss3::Filename::Data::ANIMATIONS)
    @anime = create_resource(Itefu::Animation::Effect, @as[1])
    
    @viewport = create_resource(Itefu::Rgss3::Viewport)
    @viewport.z = 1

    @scenegraph = create_resource(Itefu::SceneGraph::Root)
    @scenegraph.add_sprite(256, 32).transfer(150, 50).anchor(0.5, 0.5).
                add_child(TestFiller).resize(256, 32)
    @scenegraph.add_sprite(256, 32).transfer(300, 200).anchor(0.5, 0.5).
                add_child(TestFiller).resize(256, 32)
  end

  def on_finalize
    finalize_animations
    finalize_all_resources
  end

  def on_update
    case
    when Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_ESCAPE),
         Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_RBUTTON)
      quit
    end

    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_LBUTTON)
      unless @pressed
        x, y = Itefu::Input::Win32.position
        node = @scenegraph.hittest(x, y)
        if node
          @anime.assign_target(node.render_target.sprite, @viewport)
        else
          @anime.assign_position(x, y, @viewport)
        end
        @anime.play_speed = Rational(10 + ((rand(3)**2 - 1) * 3), 10)
        play_animation(:effect, @anime, @as[rand(3)+1])
        @pressed = true
      end
    else
      @pressed = false
    end

    @scenegraph.update
    @scenegraph.update_interaction
    @scenegraph.update_actualization
    update_animations
    @viewport.update
  end

  def on_draw
    @scenegraph.draw
  end

end
