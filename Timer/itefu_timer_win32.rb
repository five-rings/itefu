=begin
  タイマー関連のWin32APIのラッパー
=end
module Itefu::Timer::Win32
  TimeBeginPeriod = Win32API.new("winmm", "timeBeginPeriod", ['L'], 'L')
  TimeEndPeriod = Win32API.new("winmm", "timeEndPeriod", ['L'], 'L')
  TimeGetTime = Win32API.new("winmm", "timeGetTime", nil, 'L')
  QueryPerformanceCounter = Win32API.new("kernel32", "QueryPerformanceCounter", ['P'], 'L')
  QueryPerformanceFrequency = Win32API.new('kernel32','QueryPerformanceFrequency',['P'],'L')

  @@buffer = [0].pack('Q')
  @@frequency = nil

class << self

  # タイマーの分解能を設定する
  # @param [Fixnum] resolution 分解能
  def timeBeginPeriod(resolution)
    TimeBeginPeriod.call(resolution)
  end

  # タイマーの分解能の設定を解除する
  # @param [Fixnum] resolution 先にtimeBeginPeriodで設定した分解能
  def timeEndPeriod(resolution)
    TimeEndPeriod.call(resolution)
  end

  # @return [Fixnum] システム時刻を得る
  def timeGetTime
    TimeGetTime.call
  end

  # @return [Fixnum] 高分解能パフォーマンスカウンタの周波数を得る
  def queryPerformanceFrequency
    unless @@frequency
      QueryPerformanceFrequency.call(@@buffer)
      @@frequency = @@buffer.unpack('Q')[0]
    end
    @@frequency
  end

  # @return [Fixnum] 高分解能パフォーマンスカウンタのカウント値を得る  
  def queryPerformanceCounter
    QueryPerformanceCounter.call(@@buffer)
    @@buffer.unpack('Q')[0]
  end

end
end
