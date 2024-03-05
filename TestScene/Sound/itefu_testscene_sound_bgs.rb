=begin
  サウンド関連のTestScene/BGSのテスト
=end
class Itefu::TestScene::Sound::BGS < Itefu::Scene::Base
  include Itefu::Resource::Container

  class Button < Itefu::SceneGraph::Node
    include Itefu::SceneGraph::Touchable
    include Itefu::Animation::Player
    attr_accessor :clicked
    attr_reader :label

    def on_initialized(label, color)
      @label = label
      @color = color
      @anime = Itefu::Animation::Battler.new
      @anime.effect_type = Itefu::Animation::Battler::EffectType::WHITEN
      @anime.sprite = render_target.sprite
    end

    def on_finalize
      finalize_animations
      @anime.finalize
      @anime = nil
      Itefu::Sound.stop_bgs(50)
    end

    def on_updated_actualization
      update_animations
    end

    def on_draw(target)
      x = target.relative_pos_x(self)
      y = target.relative_pos_y(self)
      w = size_w
      h = size_h
      target.buffer.fill_rect(x, y, w, h, @color)
      target.buffer.draw_text(x, y, w, h, @label, Itefu::Rgss3::Bitmap::TextAlignment::CENTER)
    end

    def on_touched(x, y, kind)
      @clicked.call(self, x, y) if @clicked
      play_animation(:battler, @anime)
    end
  end

  def on_initialize
    @scenegraph = create_resource(Itefu::SceneGraph::Root)

    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 1 * 30).
                add_child(Button, "Play Fire", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_bgs("Fire") }
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 2 * 30).
                add_child(Button, "Play Wind", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_bgs_fade(0, "Wind") }

    @scenegraph.add_sprite(64, 24).transfer(175, 50 + 1 * 30).
                add_child(Button, "Stop", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.stop_bgs(1000) }

    @scenegraph.add_sprite(64, 24).transfer(275, 50 + 1 * 30).
                add_child(Button, "Vol=40", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.fade_bgs_volume(40) }
    @scenegraph.add_sprite(64, 24).transfer(275, 50 + 2 * 30).
                add_child(Button, "Vol=70", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.fade_bgs_volume(70) }
    @scenegraph.add_sprite(64, 24).transfer(275, 50 + 3 * 30).
                add_child(Button, "Vol=100", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.fade_bgs_volume(100) }
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
      unless @pressed
        x, y = Itefu::Input::Win32.position
        @pressed = @scenegraph.hittest(x, y) || false
        @pressed.touched(x,y) if @pressed
      end
    elsif @pressed
      @pressed.untouched 
      @pressed = nil
    end

    @scenegraph.update
    @scenegraph.update_interaction
    @scenegraph.update_actualization
  end
  
  def on_draw
    @scenegraph.draw
  end

end
