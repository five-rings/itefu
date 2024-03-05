=begin
  Layoutシステムでよくつかう機能を追加したキーフレームアニメーション  
=end
class Itefu::Layout::KeyFrame < Itefu::Animation::KeyFrame
  
  # このアニメーションが結び付けられているコントロール  
  def control; default_target; end
  def control=(value); self.default_target = value; end

  def play_effect(effect_id, x, y)
    context.root.view.play_effect_animation(effect_id, x, y)
  end
  
  def play_se(*args)
    Itefu::Sound.play_se(*args)
  end

  def update(*args)
    finish unless control.alive?
    super
  end
  
  def update_keyframe_animations(frame_count)
    super if control.alive?
  end

end

