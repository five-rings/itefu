
_(Window, 640, 480) {
  extend Animatable
  attribute name: :window, width: 640, height: 480, openness: 0

  animation(:in) do
    add_key  0, :openness, 0
    add_key 10, :openness, 0xff
  end

  animation(:greeting) do
    max_frame(120)
    add_trigger(10) {
      play_se("Cat")
      play_effect(1, 320, 240)
    }
  end
}

add_callback(:layouted) do
  view.play_animation(:window, :in).finisher {
    view.play_animation(:window, :greeting).finisher {
      view.play_animation(:window, :greeting)
    }
  }
end

