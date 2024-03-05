=begin
  Itefu::Input::Win32::JoyPadを使った実装
=end
class Itefu::Input::Status::Win32::JoyPad < Itefu::Input::Status::Base
  attr_reader :pad_number

  JoyPad = Itefu::Input::Win32::JoyPad
  ANALOG_1_4 = 0x3fff
  ANALOG_3_4 = 0xbfff
  
  def initialize(padnum)
    change_pad_number(padnum)
    super()
  end
  
  # 使用するパッドを変更する
  # @param [Fixnum] padnum
  def change_pad_number(padnum)
    @pad_number = padnum
    @joy_info_ex = nil
  end

  # ジョイパッドの性能をチェックする
  def check_capability
    if Itefu::Input::Win32::JoyPad.joyGetDevCaps(self.pad_number) ==Itefu::Input::Win32::JoyPad::JOYERR_NOERROR 
      caps = Itefu::Input::Win32::JoyPad.joyCapsArray
      @pov = (caps[18] & JoyPad::CapsMask::JOYCAPS_HASPOV) != 0
    else
      @pov = false
    end
  end

  # ジョイパッドデバイスのポーリングを再開する
  def restart_polling
    if @stop_polling
      @stop_polling = false
      # @note JOYERR_PARMS後ジョイパッドが刺されていても一度はエラーを返すので空呼びしておく
      Itefu::Input::Win32::JoyPad.joyGetPosEx(self.pad_number)
    end
  end

  # @return [Boolean] ジョイパッドデバイスのポーリングを停止しているか
  def polling_stopped?; @stop_polling; end
  
  def update
    return super if @stop_polling

    res = Itefu::Input::Win32::JoyPad.joyGetPosEx(self.pad_number)
    if res == Itefu::Input::Win32::JoyPad::JOYERR_NOERROR
      check_capability unless @joy_info_ex # 新規にパッドが使えるようになったとき性能チェックもしておく
      @joy_info_ex = Itefu::Input::Win32::JoyPad.joyInfoExArray
    else
      if res == Itefu::Input::Win32::JoyPad::JOYERR_PARMS
        # @note JOYERR_PARMSを返す場合にjoypad関連の処理が極端に時間がかかり処理落ちすることがあるので、その場合はジョイパッドのポーリングをやめる
        @stop_polling = true
      end
      @joy_info_ex = nil
    end

    super
  end

  def press_key?(key_code)
    return false unless @joy_info_ex

    case key_code
    when JoyPad::Code::POS_LEFT
      @joy_info_ex[2] < ANALOG_1_4
    when JoyPad::Code::POS_RIGHT
      @joy_info_ex[2] > ANALOG_3_4
    when JoyPad::Code::POS_UP
      @joy_info_ex[3] < ANALOG_1_4
    when JoyPad::Code::POS_DOWN
      @joy_info_ex[3] > ANALOG_3_4
    when JoyPad::Code::POV_UP
      v = @joy_info_ex[10]
      @pov && (JoyPad::JOY_POVFORWARD <= v) && (v < JoyPad::JOY_POVRIGHT)
    when JoyPad::Code::POV_RIGHT
      v = @joy_info_ex[10]
      @pov && (JoyPad::JOY_POVRIGHT <= v) && (v < JoyPad::JOY_POVBACKWARD)
    when JoyPad::Code::POV_DOWN
      v = @joy_info_ex[10]
      @pov && (JoyPad::JOY_POVBACKWARD <= v) && (v < JoyPad::JOY_POVLEFT)
    when JoyPad::Code::POV_LEFT
      v = @joy_info_ex[10]
      @pov && (JoyPad::JOY_POVLEFT <= v) && (v < JoyPad::JOY_POVCENTERED)
    else
      index = key_code - JoyPad::Code::BUTTON_BASE
      mask = JoyPad.joy_button_mask(index)
      (@joy_info_ex[8] & mask) != 0
    end
  end

end
