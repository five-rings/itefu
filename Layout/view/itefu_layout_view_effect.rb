=begin
  Layoutシステム/Viewにエフェクト再生機能を追加する
=end
module Itefu::Layout::View::Effect
  attr_accessor :effect_viewport
  
  def play_effect_animation(effect_id, x, y)
    effect_data = Itefu::Database.table(:animations)
    return unless effect = effect_data && effect_data[effect_id]
    anime = Itefu::Animation::Effect.new(effect).auto_finalize
    anime.assign_position(x, y, effect_viewport || viewport)
    play_raw_animation(anime.hash, anime)
  end

end
