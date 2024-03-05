=begin
  Animationのテスト用のScene/Compositeのテスト
=end
class Itefu::TestScene::Animation::Composite < Itefu::Scene::Base
  include Itefu::Animation::Player
  include Itefu::Resource::Container

  class TestFiller < Itefu::SceneGraph::Node
    def on_draw(target)
      target.buffer.fill_rect(target.relative_pos_x(self), target.relative_pos_y(self), size_w, size_h, Itefu::Color.Red)
    end
  end

  def on_initialize
    @viewport = create_resource(Itefu::Rgss3::Viewport)
    @viewport.z = 1

    @scenegraph = create_resource(Itefu::SceneGraph::Root)

    sprite1 = @scenegraph.add_sprite(32, 32).transfer(50, 50).anchor(0.5, 0.5)
    sprite1.add_child(TestFiller).resize(32, 32)

    sprite2 = @scenegraph.add_sprite(32, 32).transfer(100, 50).anchor(0.5, 0.5)
    sprite2.add_child(TestFiller).resize(32, 32)

    @as = load_data(Itefu::Rgss3::Filename::Data::ANIMATIONS)
    
    @anime = create_resource(Itefu::Animation::Composite)
    @anime.add_animation(Itefu::Animation::Effect, @as[1]).assign_target(sprite2.sprite, @viewport)
    @anime.add_animation(Itefu::Animation::KeyFrame).instance_eval {
      add_key  0, :angle,   0, bezier(0.5, 0, 0.5, 1)
      add_key 60, :angle, 360, step_end
      add_key 60, :angle,   0, step
      self
    }.default_target = sprite1.sprite
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
        play_animation(:test, @anime)
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
