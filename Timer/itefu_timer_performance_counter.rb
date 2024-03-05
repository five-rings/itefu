=begin
  高精度タイマー(秒を返す)
  @warning WindowsXP以前のOSやその他、CPUのクロック数を参照しかつクロック数が可変の環境では、正常に動作しない場合がある
=end
class Itefu::Timer::PerformanceCounter < Itefu::Timer::Base

  def initialize(manager = nil)
    super
  end

  # 高精度カウンタをタイマーの値として使う
  def time_now
    Itefu::Timer::Win32.queryPerformanceCounter
  end

private
  # 計測するのが時間でなくカウンタなので時間に変換して返すようにする
  def impl_elapsed(current, start)
    super / Itefu::Timer::Win32.queryPerformanceFrequency.to_f
  end
  
end
