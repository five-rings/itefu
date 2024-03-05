=begin  
  Windows Win32APIのラッパー
=end
module Itefu::Win32
  Sleep = Win32API.new('kernel32', 'Sleep', ['L'], nil)
  ShowCursor = Win32API.new('user32', 'ShowCursor', ['L'], 'L')
  GetCurrentProcessId = Win32API.new('kernel32', 'GetCurrentProcessId', nil, 'L')
  GetModuleFileName = Win32API.new('kernel32', 'GetModuleFileName', ['L','P','L'], 'L')
  NULL = 0
  MAX_PATH = 260

  @@fullpath = nil

class << self

  # カレントスレッドをスリープする  
  # @param [Fixnum] ms スリープする時間(ミリ秒)
  def sleep(ms)
    Sleep.call(ms)
  end
  
  # マウスカーソルの表示を切り替える
  def showCursor(enable)
    ShowCursor.call(enable ? 1 : 0)
  end
  
  # @return [Fixnum] このアプリケーションのプロセスID
  def getCurrentProcessId
    GetCurrentProcessId.call
  end
  
  # @return [String] 実行ファイルのファイル名をフルパスで返す
  def getModuleFileName(buffer = ([0] * MAX_PATH).pack('L*'))
    size = GetModuleFileName.call(NULL, buffer, MAX_PATH)
    buffer[0, size]
  end
  
  # @return [String] 実行ファイルの置かれたフルパスを返す
  def getModuleFullPath
    @@fullpath ||= File.dirname(getModuleFileName)
  end

end
end
