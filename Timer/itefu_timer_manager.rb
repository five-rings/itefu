=begin
  時間関連の毎フレーム更新する処理を行う
=end
class Itefu::Timer::Manager < Itefu::System::Base
  attr_reader :frame_time   # [Fixnum] 同一フレーム内で同じ値になるタイマー

  # @return [Fixnum] このフレーム内での経過時間
  def frame_time_elapsed
    now = Itefu::Timer::Win32.timeGetTime
    if @frame_time <= now
      now - @frame_time
    else
      Itefu::Timer::Manager.rounded(now, @frame_time)
    end
  end

  # タイマーのカウントがラウンドした場合の処理
  # @return [Fixnum] 指定した時間同士の差
  # @param [Fixnum] current 現在の時刻
  # @param [Fixnum] start 計測しはじめた時刻
  # @warning start > current である場合にのみ呼んでよい
  def self.rounded(current, start)
    ITEFU_DEBUG_ASSERT(start > current)
    0xffffffff - start + current + 1
  end

private

  def on_initialize
    # タイマーの精度を1ミリ秒に設定する
    Itefu::Timer::Win32.timeBeginPeriod(1)
    update_frame_timer
  end
  
  def on_finalize
    # タイマーの精度を元に戻す
    Itefu::Timer::Win32.timeEndPeriod(1)
  end

  def on_update
    update_frame_timer
  end

  # フレームタイマを更新する
  def update_frame_timer
    @frame_time = Itefu::Timer::Win32.timeGetTime
  end

end
