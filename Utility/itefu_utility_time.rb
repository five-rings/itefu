=begin
  時間関連の便利機能
=end
module Itefu::Utility::Time
class << self 

  # @return [Fixnum] フレーム数をミリ秒に変換する
  def frame_to_millisecond(frame)
    frame * 1000 / Graphics.frame_rate
  end

  # @return [Fixnum] ミリ秒をフレーム数に変換する
  def millisecond_to_frame(ms)
    ms * Graphics.frame_rate / 1000
  end
  
  # 秒数をhh:mm:ss書式に変換する
  def second_to_hms(sec, format = "%02d:%02d:%02d")
    format % [sec / 3600, sec / 60 % 60, sec % 60]
  end

  # ミリ秒をmm:ss.d書式に変換する
  def millisecond_to_msd(ms, format = "%02d'%02d\"%02d")
    format % [ms / 60000, ms / 1000 % 60, ms % 1000 / 10]
  end

end
end
