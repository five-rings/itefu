=begin
  Itefu::Input::Win32を使った実装
=end
class Itefu::Input::Status::Win32 < Itefu::Input::Status::Base
  attr_optional_value :position_x
  attr_optional_value :position_y

  def press_key?(key_code)
    Itefu::Input::Win32.press_key?(key_code)
  end

  def update
    x, y = Itefu::Input::Win32.position
    @optional_values[:position_x] = x
    @optional_values[:position_y] = y
    super
  end

end
