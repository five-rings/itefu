=begin
  タイマーの基底クラス
 時間の取得方法を派生先で実装する
=end
class Itefu::Timer::Base
  attr_reader :manager    # [Timer::Manager]

  # @return [Fixnum] 現在の時刻を得る
  # @note 派生先でオーバーライドする
  def time_now
    raise Itefu::Exception::NotImplemented
  end

  # @return [Fixnum] 経過時間を得る
  def elapsed(started = @started)
    if @paused
      impl_elapsed(@paused, started)
    else
      impl_elapsed(time_now, started)
    end
  end

  # タイマーをリセットする
  def reset
    @started = time_now
  end

  # タイマーをポーズする  
  def pause
    return if @paused
    @paused = time_now
  end
  
  # ポーズしたタイマーを再開する
  def resume
    return unless @paused
    @started -= (time_now - @paused)  # ポーズしていた分を控除する
    @paused = nil
  end
  
private

  def initialize(manager)
    @manager = manager if manager
    @paused = nil
    reset
  end

  # @return [Fixnum] 指定した時間同士の差を計算する
  # @param [Fixnum] current 現在の時刻
  # @param [Fixnum] start 計測しはじめた時刻
  def impl_elapsed(current, start)
    if start <= current
      current - start
    else
      rounded(current, start)
    end
  end
  
  # タイマーのカウントがラウンドした場合の処理
  # @return [Fixnum] 指定した時間同士の差
  # @param [Fixnum] current 現在の時刻
  # @param [Fixnum] start 計測しはじめた時刻
  def rounded(current, start)
    Itefu::Timer::Manager.rounded(current, start)
  end

end
