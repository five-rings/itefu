=begin  
  ウィンドウ関連
=end
module Itefu::Win32
  ShowWindow = Win32API.new('user32', 'ShowWindow', ['L','L'], 'L')
  GetTopWindow = Win32API.new('user32', 'GetTopWindow', ['L'], 'L')
  GetWindowThreadProcessId = Win32API.new('user32', 'GetWindowThreadProcessId', ['L', 'P'], 'L')
  GetWindow = Win32API.new('user32', 'GetWindow', ['L', 'L'], 'L')
  GetWindowRect = Win32API.new('user32', 'GetWindowRect', ['L','P'], 'L')
  SetWindowPos = Win32API.new('user32', 'SetWindowPos', ['L','L','L','L','L','L','L'], 'L')
  SetForegroundWindow = Win32API.new('user32', 'SetForegroundWindow', ['L'], 'L')
  SetActiveWindow = Win32API.new('user32', 'SetActiveWindow', ['L'], 'L')
  BringWindowToTop = Win32API.new('user32', 'BringWindowToTop', ['L'], 'L')
  GetClassName = Win32API.new('user32', 'GetClassName', ['L', 'P', 'L'], 'L')
  GetWindowLong = Win32API.new('user32', 'GetWindowLong', ['L','L'], 'L')


  GW_HWNDNEXT = 2
  SW_HIDE = 0
  SW_SHOW = 5
  HWND_TOP = 0
  HWND_TOPMOST = -1
  HWND_NOTOPMOST = -2
  SWP_NOSIZE = 1
  SWP_NOMOVE = 2
  SWP_NOZORDER = 4
  GWL_STYLE = -16
  WS_POPUP = 0x80000000

  @@hwnd = nil

class << self
  
  # ウィンドウを表示する
  # @param [Fixnum] hwnd 対象のウィンドウのハンドル
  # @param [Fixnum] cmd ウィンドウの表示状態を示す値
  def showWindow(hwnd, cmd = SW_SHOW)
    ShowWindow.call(hwnd, cmd)
  end

  # ウィンドウを非表示にする
  # @param [Fixnum] hwnd 対象のウィンドウのハンドル
  def hideWindow(hwnd)
    showWindow(hwnd, SW_HIDE)
  end

  # @return [Fixnum] Zオーダーが最上位のウィンドウハンドル
  # @param [Fixnum] hwnd 対象のウィンドウのハンドル, NULLで全体を探す
  def getTopWindow(hwnd = NULL)
    GetTopWindow.call(hwnd)
  end
  
  # @return [Fixnum] 指定したウィンドウの次のオーダーのウィンドウのハンドル
  # @param [Fixnum] hwnd 対象のウィンドウのハンドル
  def getNextWindow(hwnd)
    GetWindow.call(hwnd, GW_HWNDNEXT)
  end
  
  # @return [Fixnum] 指定したウィンドウを生成したプロセスのID
  # @param [Fixnum] hwnd 対象のウィンドウのハンドル
  # @param [String] buffer 事前に生成したバッファを外部から指定する
  def getWindowThreadProcessId(hwnd, buffer = [0].pack('L'))
    GetWindowThreadProcessId.call(hwnd, buffer)
    buffer.unpack('L')[0]
  end

  # @return [String] 指定したウィンドウのClassName
  # @parma [Fixnum] 対象のウィンドウのハンドル
  def getWindowClassName(hwnd)
    buffer = " " * 128
    GetClassName.call(hwnd, buffer, buffer.size-1)
    buffer.strip!
    buffer
  end
  
  # @return [Fixnum] このゲームが動作しているウィンドウのハンドル
  def getWindowHandle
    unless @@hwnd
      # ウィンドウの属するプロセスIDと自身のプロセスIDとが一致するものを探す
      pid = getCurrentProcessId
      hwnd = getTopWindow
      buffer = [0].pack('L')
      while (hwnd != NULL)
        if getWindowThreadProcessId(hwnd, buffer) == pid
          @@hwnd = hwnd
          if "RGSS Player" == getWindowClassName(hwnd)
            break
          end
        else
          # 他のプロセスに探しているウィンドウはないので
          break if @@hwnd
        end
        hwnd = getNextWindow(hwnd)
      end
    end
    @@hwnd
  end
  
  # @return [Array<Fixnum>] ウィンドウの位置x, yを返す
  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  def getWindowPos(hwnd, buffer = ([0] * 4).pack('i*'))
    GetWindowRect.call(hwnd, buffer)
    buffer.unpack('i*')[0, 2]
  end
  
  # ウィンドウの位置を変更する
  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  # @param [Fixnum] x 移動先のx座標
  # @param [Fixnum] y 移動先のy座標
  def setWindowPos(hwnd, x, y)
    SetWindowPos.call(hwnd, HWND_TOP, x, y, 0, 0, SWP_NOSIZE)
  end
  
  # ウィンドウを前面に送る
  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  def bringWindowToTop(hwnd)
    BringWindowToTop.call(hwnd)
  end
  
  # ウィンドウをアクティブにする
  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  def setActiveWindow(hwnd)
    SetActiveWindow.call(hwnd)
  end
  
  # ウィンドウをフォアグラウンドにする
  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  def setForegroundWindow(hwnd)
    SetForegroundWindow.call(hwnd)
  end

  # ウィンドウを無理矢理前面に送る
  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  def setTopWindowForcibly(hwnd)
    SetWindowPos.call(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE)
    SetWindowPos.call(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOSIZE | SWP_NOMOVE)
  end

  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  # @return [Fixnum] ウィンドウスタイル
  def getWindowStyle(hwnd)
    GetWindowLong.call(hwnd, GWL_STYLE) 
  end

  # @param [Fixnum] hwnd 対象のウィンドウハンドル
  # @return [Boolean] 現在フルスクリーンか
  def fullScreenMode?(hwnd)
    # フルスクリーンモード時はWS_CAPTIONが外れてWS_POPUPになるので簡易的にそれで判定する
    (getWindowStyle(hwnd) & WS_POPUP) == WS_POPUP
  end

end
end
