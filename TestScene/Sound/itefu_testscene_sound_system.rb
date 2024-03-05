=begin
  サウンド関連のTestScene/System定義の音のテスト
=end
class Itefu::TestScene::Sound::System < Itefu::Scene::Base
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

    # SE
    24.times.each do |i|
      @scenegraph.add_sprite(64, 24).transfer(175 + (i/8)*100, 50 + (i%8) * 30).
                  add_child(Button, "SE #{i}", Itefu::Color.Blue).resize(64, 24).
                  clicked = proc { Itefu::Sound.play_system_se(i) }
    end

    # Stop
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 9*30).
                add_child(Button, "Stop", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.stop_me(500); Itefu::Sound.stop_bgm(500) }
    # BGM
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 0*30).
                add_child(Button, "Title", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_title_bgm }
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 1*30).
                add_child(Button, "Battle", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_battle_bgm }
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 2*30).
                add_child(Button, "Boat", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_boat_bgm }
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 3*30).
                add_child(Button, "Ship", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_ship_bgm }
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 4*30).
                add_child(Button, "AirShip", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_airship_bgm }
    # ME
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 6*30).
                add_child(Button, "BattleEnd", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_battle_end_me }
    @scenegraph.add_sprite(64, 24).transfer(75, 50 + 7*30).
                add_child(Button, "GameOver", Itefu::Color.Blue).resize(64, 24).
                clicked = proc { Itefu::Sound.play_gameover_me }
  end

  def on_finalize
    finalize_all_resources
  end

  def on_update
    quit if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_ESCAPE)

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
