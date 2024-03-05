=begin
  同一フレーム内なら同じ時間を返すタイマー(ミリ秒を返す)
=end
class Itefu::Timer::Frame < Itefu::Timer::Base

  # フレーム内で同一の時間をタイマーの値として使う
  def time_now
    manager.frame_time
  end
  
end
