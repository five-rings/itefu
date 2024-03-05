=begin
  Animationのテスト用のScene
=end
class Itefu::TestScene::Animation::KeyFrame < Itefu::Scene::Base
  include Itefu::Animation::Player
  include Itefu::Resource::Container

  class TestFiller < Itefu::SceneGraph::Node
    def on_draw(target)
      target.buffer.fill_rect(target.relative_pos_x(self), target.relative_pos_y(self), size_w, size_h, Itefu::Color.Red)
    end
  end
  
  class TestAnimation < Itefu::Animation::Base
    def on_initialize(target)
      @target = target
    end

    def on_update(delta)
      @target.sprite.angle = (@play_count * 5).to_i % 360
      if @play_count > 120
        finish
      end
    end
    
    def on_finish
      @target.sprite.angle = 0 unless @target.sprite.disposed?
    end
  end

  def on_initialize
    @scenegraph = create_resource(Itefu::SceneGraph::Root)

    sprite = @scenegraph.add_sprite(32, 32).transfer(50, 50).anchor(0.5, 0.5)
    sprite.add_child(TestFiller).resize(32, 32)
    @anime = create_resource(TestAnimation, sprite)

    sprite2 = @scenegraph.add_sprite(32, 32).transfer(100, 50).anchor(0.5, 0.5)
    sprite2.add_child(TestFiller).resize(32, 32)
    anime2 = create_resource(Itefu::Animation::KeyFrame)
    anime2.instance_eval {
      loop true
      add_key  0, :angle,   0, bezier(0.5, 0, 0.5, 1)
      add_key 60, :angle, 360, step
    }
    anime2.default_target = sprite2.sprite
    play_animation(:test2, anime2)
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

    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_RETURN)
      unless @pushed
        @pushed = true
        played = play_animation(:test, @anime)
        played.play_speed = (rand(4) + 1) if played
      end
    else
      @pushed = false
    end
    
    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_SHIFT)
      self.animation_speed = Rational(1, 2)
    else
      self.animation_speed = 1
    end

    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_SPACE)
      anime = self.animation(:test)
      anime.finish if anime
    end

    @scenegraph.update
    @scenegraph.update_interaction
    @scenegraph.update_actualization
    update_animations
  end
  
  def on_draw
    @scenegraph.draw
  end

end
