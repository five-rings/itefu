=begin
  Layoutシステム/アニメーションを追加する  
=end
module Itefu::Layout::Control::Animatable
  include Itefu::Layout::Control::Callback
  
  def self.extended(object)
    object.initialize_animation_variables
  end
  
  def initialize(*args)
    super
    initialize_animation_variables
  end
  
  def initialize_animation_variables
    @animations ||= {}
  end
  
  def finalize
    super
    @animations.each_value(&:finalize)
    @animations.clear
  end
  
  def animation_key(id)
    @animations[id].hash
  end
  
  def animation_data(id)
    @animations[id]
  end

  def add_animation(id, klass, *args, &block)
    remove_animation(id)
    anime = klass.new(*args)
    anime.context = self
    anime.instance_eval(&block) if block
    @animations[id] = anime
    execute_callback(:added_animation)
    anime
  end
  
  def remove_animation(id)
    anime = @animations.delete(id)
    execute_callback(:removed_animation) if anime
    anime
  end

end