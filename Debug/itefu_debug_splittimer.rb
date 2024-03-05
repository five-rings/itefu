=begin
  区間の経過時間を計測しデバッグログに出力する
=end
class Itefu::Debug::SplitTimer
  attr_reader :timer

  def initialize(label = nil)
    @timer = Itefu::Timer::PerformanceCounter.new
    @label = formated_label(label) if label
  end

  # @param [String] message ログに表示する文字列
  # @return [SplitTimer] レシーバー自身を返す
  # @note messageを省略するとログを表示しない
  def start(message = nil)
    @timer.reset
    @last_elaption = 0
    output_log(message, 0)
    self
  end
 
  # @param [String] message ログに表示する文字列
  # @return [Float] 前回の計測からの経過時間を返す
  # @note messageを省略するとログを表示しない
  def check(message)
    elaption = @timer.elapsed
    delta = elaption - @last_elaption
    output_log(message, elaption * 1000, delta * 1000)
    @last_elaption = elaption
    delta
  end
  
  # @param [String] message ログに表示する文字列
  # @param [Float] elaption startからの経過時間 (ミリ秒)
  # @param [Float] delta 前回のcheckからの経過時間 (ミリ秒)
  def output_log(message, elaption, delta = nil)
    return unless message
    if delta
      ITEFU_DEBUG_OUTPUT_NOTICE("split#{@label}: %9.3f, d:%8.3f, #{message}" % [elaption, delta])
    else
      ITEFU_DEBUG_OUTPUT_NOTICE("split#{@label}: %9.3f, #{message}" % elaption)
    end
  end

  # @return [Fixnum] 現在の経過時間を返す
  def sliptime(start = nil)
    if start
      @timer.elapsed(start)
    else
      @timer.time_now
    end
  end
  
  # ブロックの処理時間を計測してログに出力する
  # @param [String] message ログに表示する文字列
  def self.measure(message)
    @@timer ||= Itefu::Debug::SplitTimer.new("*")
    n = @@timer.sliptime
    yield
    n = @@timer.sliptime(n)
    @@timer.output_log(message, n * 1000)
  end

private

  def formated_label(label)
    " (#{label})"
  end

end
