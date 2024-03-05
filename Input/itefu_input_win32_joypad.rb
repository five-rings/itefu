=begin
  Win32APIでのジョイパッドの入力状態を取得するラッパー
=end
module Itefu::Input::Win32::JoyPad
  JoyGetPosEx = Win32API.new("winmm", "joyGetPosEx", ['L', 'P'], 'L')
  JoyGetNumDevs = Win32API.new("winmm", "joyGetNumDevs", 'v', 'L')
  JoyGetDevCaps = Win32API.new("winmm", "joyGetDevCaps", ['L', 'P', 'L'], 'L')
  JoyInfoEx = Struct.new(:dwSize, :dwFlags,
                         :dwXpos, :dwYpos, :dwZpos,
                         :dwRpos, :dwUpos, :dwVpos,
                         :dwButtons, :dwButtonNumber,
                         :dwPOV, 
                         :dwReserved1, :dwReserved2)
  INFO_FORMAT = 'L' * JoyInfoEx.members.size

  JoyCaps = Struct.new(:wMid, :wPid,
                       :szPname,
                       :wXmin, :wXmax,
                       :wYmin, :wYmax,
                       :wZmin, :wZmax,
                       :wNumButtons,
                       :wPeriodMin, :wPeriodMax,
                       :wRmin, :wRmax,
                       :wUmin, :wUmax,
                       :wVmin, :wVmax,
                       :wCaps,
                       :wMaxAxes, :wNumAxes,
                       :wMaxButtons,
                       :szRegKey,
                       :szOEMVxD)
  CAPS_FORMAT = 'SSA32' + 'L'*19 +'A32A260'

  MMSYSERR_BASE         = 0
  MMSYSERR_NODRIVER     = MMSYSERR_BASE + 6
  MMSYSERR_INVALPARAM   = MMSYSERR_BASE + 11
  MMSYSERR_BADDEVICEID  = MMSYSERR_BASE + 2

  JOYERR_BASE         = 160
  JOYERR_NOERROR      = 0                  
  JOYERR_PARMS        = JOYERR_BASE + 5      
  JOYERR_NOCANDO      = JOYERR_BASE + 6      
  JOYERR_UNPLUGGED    = JOYERR_BASE + 7      

  JOY_POVCENTERED     = 0xffff
  JOY_POVFORWARD      = 0
  JOY_POVRIGHT        = 9000
  JOY_POVBACKWARD     = 18000
  JOY_POVLEFT         = 27000

  JOY_RETURNX         = 0x00000001
  JOY_RETURNY         = 0x00000002
  JOY_RETURNZ         = 0x00000004
  JOY_RETURNR         = 0x00000008
  JOY_RETURNU         = 0x00000010
  JOY_RETURNV         = 0x00000020
  JOY_RETURNPOV       = 0x00000040
  JOY_RETURNBUTTONS   = 0x00000080
  JOY_RETURNRAWDATA   = 0x00000100
  JOY_RETURNPOVCTS    = 0x00000200
  JOY_RETURNCENTERED  = 0x00000400
  JOY_USEDEADZONE     = 0x00000800
  JOY_RETURNALL       = (JOY_RETURNX | JOY_RETURNY | JOY_RETURNZ |
                         JOY_RETURNR | JOY_RETURNU | JOY_RETURNV |
                         JOY_RETURNPOV | JOY_RETURNBUTTONS)
  JOY_CAL_READALWAYS  = 0x00010000
  JOY_CAL_READXYONLY  = 0x00020000
  JOY_CAL_READ3       = 0x00040000
  JOY_CAL_READ4       = 0x00080000
  JOY_CAL_READXONLY   = 0x00100000
  JOY_CAL_READYONLY   = 0x00200000
  JOY_CAL_READ5       = 0x00400000
  JOY_CAL_READ6       = 0x00800000
  JOY_CAL_READZONLY   = 0x01000000
  JOY_CAL_READRONLY   = 0x02000000
  JOY_CAL_READUONLY   = 0x04000000
  
  module CapsMask
    JOYCAPS_HASZ      = 1 
    JOYCAPS_HASR      = 2 
    JOYCAPS_HASU      = 4 
    JOYCAPS_HASV      = 8 
    JOYCAPS_HASPOV    = 16 
    JOYCAPS_POV4DIR   = 32 
    JOYCAPS_POVCTS    = 64 
  end

  module ButtonMask  
    JOY_BUTTON1       = 0x0001
    JOY_BUTTON2       = 0x0002
    JOY_BUTTON3       = 0x0004
    JOY_BUTTON4       = 0x0008
    JOY_BUTTON1CHG    = 0x0100
    JOY_BUTTON2CHG    = 0x0200
    JOY_BUTTON3CHG    = 0x0400
    JOY_BUTTON4CHG    = 0x0800

    JOY_BUTTON5       = 0x00000010
    JOY_BUTTON6       = 0x00000020
    JOY_BUTTON7       = 0x00000040
    JOY_BUTTON8       = 0x00000080
    JOY_BUTTON9       = 0x00000100
    JOY_BUTTON10      = 0x00000200
    JOY_BUTTON11      = 0x00000400
    JOY_BUTTON12      = 0x00000800
    JOY_BUTTON13      = 0x00001000
    JOY_BUTTON14      = 0x00002000
    JOY_BUTTON15      = 0x00004000
    JOY_BUTTON16      = 0x00008000
    JOY_BUTTON17      = 0x00010000
    JOY_BUTTON18      = 0x00020000
    JOY_BUTTON19      = 0x00040000
    JOY_BUTTON20      = 0x00080000
    JOY_BUTTON21      = 0x00100000
    JOY_BUTTON22      = 0x00200000
    JOY_BUTTON23      = 0x00400000
    JOY_BUTTON24      = 0x00800000
    JOY_BUTTON25      = 0x01000000
    JOY_BUTTON26      = 0x02000000
    JOY_BUTTON27      = 0x04000000
    JOY_BUTTON28      = 0x08000000
    JOY_BUTTON29      = 0x10000000
    JOY_BUTTON30      = 0x20000000
    JOY_BUTTON31      = 0x40000000
    JOY_BUTTON32      = 0x80000000
  end

  module Code
    POS_LEFT  = 0
    POS_RIGHT = 1
    POS_UP    = 2
    POS_DOWN  = 3
    POV_UP    = 6
    POV_RIGHT = 7
    POV_DOWN  = 8
    POV_LEFT  = 9

    BUTTON_BASE = 10
    Itefu::Utility::Module.declare_enumration(self, 32.times.map {|i|
      :"BUTTON#{i}"
    }, BUTTON_BASE)
  end
  
  # @param [Fixnum] index マスクを取得したいボタン番号
  # @note index は JOY_BUTTONn の n とは異なり、0から始まるので注意
  def self.joy_button_mask(index)
    1 << index
  end

  # @return [String] JoyInfoEx相当のバッファを作成する
  # @param [Fixnum] flag dwFlagsに設定する値
  def self.create_joyinfoex_buffer(flag)
    size = JoyInfoEx.members.size
    ([4 * size, flag].concat Array.new(size - 2, 0)).pack(INFO_FORMAT)
  end
  #
  @@info_buffer = create_joyinfoex_buffer(JOY_RETURNALL)
  
  # @return [String] JoyCaps相当のバッファを作成する  
  def self.create_joycaps_buffer
    b = Array.new(JoyCaps.members.size, 0)
    b[2] = b[-1] = b[-2] = ""
    b.pack(CAPS_FORMAT)
  end
  #
  @@caps_buffer = create_joycaps_buffer

  # joyGetPosExを呼ぶ
  # @note idに指定できるのは joyGetNumDevs で取得できる未満の値
  # @param [Fixnum] id ジョイパッドの識別子
  # @return [Fixnum] エラーコード
  def self.joyGetPosEx(id, buffer = nil)
    buffer ||= @@info_buffer
    JoyGetPosEx.call(id, buffer)
  end
  
  # @return [Fixnum] 使用できるジョイパッドの数を取得する
  def self.joyGetNumDevs
    JoyGetNumDevs.call
  end
  
  # joyGetDevCapsを呼ぶ
  # @param [Fixnum] id ジョイパッドの識別子
  # @return [Fixnum] エラーコード
  def self.joyGetDevCaps(id, buffer = nil)
    buffer ||= @@caps_buffer
    JoyGetDevCaps.call(id, buffer, buffer.size)
  end
  
  # @return [JoyInfoEx] 直前に呼んだjoyGetPosExの結果
  def self.joyInfoEx(info = nil, buffer = nil)
    if info
      joyInfoExArray(buffer).each.with_index do |v, i|
        info[i] = v
      end
      info
    else
      JoyInfoEx.new(*joyInfoExArray(buffer))
    end
  end
  
  # @return [Array] JoyInfoExのメンバを先頭から格納した配列
  def self.joyInfoExArray(buffer = nil)
    (buffer || @@info_buffer).unpack(INFO_FORMAT)
  end
  
  # @return [JoyCaps] 直前に呼んだjoyGetDevCapsの結果
  def self.joyCaps(caps = nil, buffer = nil)
    if caps
      joyCapsArray(buffer).each.with_index do |v, i|
        caps[i] = v
      end
      caps
    else
      JoyCaps.new(*joyCapsArray(buffer))
    end
  end

  # @return [Array] JoyCapsのメンバを戦闘から格納した配列
  def self.joyCapsArray(buffer = nil)
    (buffer || @@caps_buffer).unpack(CAPS_FORMAT)
  end

end

