=begin  
  itefu-hookを使用したウィンドウメッセージのフック
=end
module Itefu::Win32::Hook
  FILENAME = 'System/itefu_hook.dll'

  def self.enable(hwnd)
    extend HookWindowMessage
    start(hwnd)
  end
  
  module HookWindowMessage
    def self.extended(object)
      Itefu::Utility::Module.define_const(self, :Start) do
        Win32API.new(FILENAME, "Start", ['i'], 'v')
      end
      Itefu::Utility::Module.define_const(self, :HookWindowMessage) do
        Win32API.new(FILENAME, "HookWindowMessage", ['i', 'i'], 'v')
      end
      Itefu::Utility::Module.define_const(self, :UnhookWindowMessage) do
        Win32API.new(FILENAME, "UnhookWindowMessage", 'i', 'i')
      end
      Itefu::Utility::Module.define_const(self, :UnhookAllWindowMessages) do
        Win32API.new(FILENAME, "UnhookAllWindowMessages", 'v', 'v')
      end
      Itefu::Utility::Module.define_const(self, :IsWindowMessageSent) do
        Win32API.new(FILENAME, "IsWindowMessageSent", 'i', 'i')
      end
      Itefu::Utility::Module.define_const(self, :GetWParam) do
        Win32API.new(FILENAME, "GetWParam", 'i', 'i')
      end
      Itefu::Utility::Module.define_const(self, :GetLParam) do
        Win32API.new(FILENAME, "GetLParam", 'i', 'i')
      end
      Itefu::Utility::Module.define_const(self, :Flush) do
        Win32API.new(FILENAME, "Flush", 'v', 'v')
      end
    end

    # ウィンドウプロシージャのフックを開始する
    def start(hwnd)
      Start.call(hwnd)
    end
    
    # ウィンドウメッセージをフックする
    # @param [Fixnum] message_id ウィンドウメッセージの番号
    # @param [Boolean] mask フックしたメッセージを握りつぶすか
    def hook_window_message(message_id, to_mask)
      HookWindowMessage.call(message_id, to_mask ? 1 : 0)
    end
    
    # ウィンドウメッセージのフックを解除する
    # @param [Fixnum] message_id ウィンドウメッセージの番号
    # @return [Fixnum] フックしていない場合は0を返す
    def unhook_window_message(message_id)
      UnhookWindowMessage.call(message_id)
    end
    
    # 全てのフックを解除する
    def unhook_all_window_messages
      UnhookAllWindowMessages.call
    end
    
    # @return [Boolean] ウィンドウメッセージを握りつぶしたか
    # @param [Fixnum] message_id ウィンドウメッセージの番号
    def window_message_sent?(message_id)
      IsWindowMessageSent.call(message_id) > 0
    end

    # @return [Fixnum] 握りつぶしたウィンドウメッセージのWPARAMを取得する
    # @warning window_message_sent?がtrueであることを確認してから呼ぶ
    # @param [Fixnum] message_id ウィンドウメッセージの番号
    def wparam(message_id)
      GetWParam.call(message_id)
    end
    
    # @return [Fixnum] 握りつぶしたウィンドウメッセージのLPARAMを取得する
    # @warning window_message_sent?がtrueであることを確認してから呼ぶ
    # @param [Fixnum] message_id ウィンドウメッセージの番号
    def lparam(message_id)
      GetLParam.call(message_id)
    end

    # window_message_sent? をfalseに戻す
    def flush
      Flush.call
    end
  end
end
