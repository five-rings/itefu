=begin
  サウンド関連のTestScene/音源との距離による減衰のテスト
=end
class Itefu::TestScene::Sound::Environment < Itefu::Scene::Base
  include Itefu::Resource::Container
  include Itefu::Animation::Player

  class Source < Itefu::SceneGraph::Node
    include Itefu::SceneGraph::Touchable
    include Itefu::Animation::Player
    attr_accessor :moved
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
      @last_x = x
      @last_y = y
    end
    
    def on_touching(x, y, kind)
      @last_x = x
      @last_y = y
    end
    
    def on_untouched(kind)
      x = @last_x - size_w/2
      y = @last_y - size_h/2
      render_target.transfer(x, y)
      moved.call(x, y)
    end
  end

  def on_initialize
    Itefu::Sound.environment.play_bgs(:fire, 0, 0, "Fire")
    Itefu::Sound.environment.play_bgs(:wind, 0, 0, "Wind")

    @scenegraph = create_resource(Itefu::SceneGraph::Root)

    @scenegraph.add_sprite(32, 32).transfer((Graphics.width-32)/2, (Graphics.height-32)/2).
                add_child(Source, "耳", Itefu::Color.Blue).resize(32, 32).
                moved = proc {|x, y|
                  Itefu::Sound.environment.move_listener(x, y)
                }.tap {|p| p.call((Graphics.width-32)/2, (Graphics.height-32)/2) }

    @scenegraph.add_sprite(32, 32).transfer(100, 50).
                add_child(Source, "炎", Itefu::Color.Red).resize(32, 32).
                moved = proc {|x, y|
                  Itefu::Sound.environment.move_bgs(:fire, x, y)
                }.tap {|p| p.call(100, 50) }

    @scenegraph.add_sprite(32, 32).transfer(Graphics.width-100-32, 50).
                add_child(Source, "風", Itefu::Color.Red).resize(32, 32).
                moved = proc {|x, y|
                  Itefu::Sound.environment.move_bgs(:wind, x, y)
                }.tap {|p| p.call(Graphics.width-100-32, 50) }

    @as = load_data(Itefu::Rgss3::Filename::Data::ANIMATIONS)
    @anime = create_resource(Itefu::Animation::Effect, @as[1]).tap {|anime| anime.sound_env = Itefu::Sound.environment }
  end

  def on_finalize
    finalize_animations
    finalize_all_resources
    Itefu::Sound.environment.clear_bgs(50)
    Itefu::Sound.stop_bgs(50)
  end

  def on_update
    quit if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_ESCAPE)

    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_LBUTTON)
      x, y = Itefu::Input::Win32.position
      if @pressed_l
        @pressed_l.touching(x, y)
      elsif @pressed_l.nil?
        @pressed_l = @scenegraph.hittest(x, y) || false
        if @pressed_l
          @pressed_l.touched(x,y) 
        else
          Itefu::Sound.stop_bgs
        end
      end
    else
      @pressed_l.untouched if @pressed_l
      @pressed_l = nil
    end

    if Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_RBUTTON)
      unless @pressed_r
        x, y = Itefu::Input::Win32.position
        @anime.assign_position(x, y)
        play_animation(:effect, @anime)
        @pressed_r = true
        Itefu::Sound.play_bgs("Rain")
      end
    elsif @pressed_r
      @pressed_r = false
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
