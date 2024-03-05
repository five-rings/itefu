=begin
  実時間タイマー(ミリ秒を返す)
=end
class Itefu::Timer::Real < Itefu::Timer::Base

  def initialize(manager = nil)
    super
  end

  # 現在の実時間をタイマーの値として使う
  def time_now
    Itefu::Timer::Win32.timeGetTime
  end

end
