=begin
  パフォーマンス計測やその表示関連
=end
class Itefu::Debug::Performance::Counter
  attr_reader :elapsed    # [Fixnum] 最後に measureを実行した際に計測した時間
  @@timer = Itefu::Timer::Real.new

  def initialize
    @elapsed = 0
  end

  # ブロックを実行し、実行時間を計測する
  def measure
    @@timer.reset
    yield
    @elapsed = @@timer.elapsed
  end

end
