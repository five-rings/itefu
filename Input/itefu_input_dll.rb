=begin
  itefu_input.dllを使用する  
  Input::Manager に KeySurpression を追加する
  Input::Status::Win32 に MouseWheel を追加する
=end
module Itefu::Input::Dll
  FILENAME = 'System/itefu_input.dll'
  
  def self.extended(system)
    ITEFU_DEBUG_ASSERT(Itefu::Input::Manager === system)
    system.extend KeySurpression
    Itefu::Input::Status::Win32.send(:include, MouseWheel)
  end

  module KeySurpression
    def self.extended(object)
      Itefu::Utility::Module.define_const(self, :SetWindowHandle) do
        Win32API.new(FILENAME, "SetWindowHandle", ['i'], 'v')
      end
      Itefu::Utility::Module.define_const(self, :AddKeyToSuppress) do
        Win32API.new(FILENAME, "AddKeysToSuppress", ['i', 'p'], 'v')
      end
      Itefu::Utility::Module.define_const(self, :ClearKeysToSuppress) do
        Win32API.new(FILENAME, "ClearKeysToSuppress", 'v', 'v')
      end
      Itefu::Utility::Module.define_const(self, :IsKeySuppressed) do
        Win32API.new(FILENAME, "IsKeySuppressed", 'i', 'i')
      end
    end

    # ウィンドウハンドルを設定しなおす
    def set_window_handle(hwnd)
      SetWindowHandle.call(hwnd)
      self
    end

    # 入力を抑制したいキーを設定する
    # @param [Itefu::Input::Win32::Code] *args
    def add_keys_to_suppress(*args)
      AddKeyToSuppress.call(args.size, args.pack('i*'))
    end
    
    # 設定したキー入力の抑制を解除する
    def clear_keys_to_suppress
      ClearKeysToSuppress.call
    end
    
    # @return [Boolean] 指定したキーを抑制したか
    # @note 抑制していた場合、チェックした時点でfalseに戻す
    # @param [Itefu::Input::Win32::Code] code
    def key_suppressed?(code)
      IsKeySuppressed.call(code) != 0
    end
  end

  module MouseWheel
    WHEEL_DELTA = 120

    def self.included(klass)
      Itefu::Utility::Module.define_const(self, :GetMouseWheelDeltaX) {
        Win32API.new(FILENAME, "GetMouseWheelDeltaX", 'v', 'i') 
      }
      Itefu::Utility::Module.define_const(self, :GetMouseWheelDeltaY) {
        Win32API.new(FILENAME, "GetMouseWheelDeltaY", 'v', 'i') 
      }
      klass.class_eval do
        attr_optional_value :scroll_x
        attr_optional_value :scroll_y
      end
    end

    def update
      # GetMouseWheelDeltaX/Yは、呼ばれるまでのDeltaを全て加算するので、毎フレーム呼ぶ
      @optional_values[:scroll_x] =  GetMouseWheelDeltaX.call / WHEEL_DELTA
      @optional_values[:scroll_y] = -GetMouseWheelDeltaY.call / WHEEL_DELTA  # WM_MOUSEWHEELは上がプラスなので符号を反転する
      super
    end
  end

end
