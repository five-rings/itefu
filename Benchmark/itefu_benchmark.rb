=begin
  処理速度を計測する
=end
module Itefu::Benchmark

  # Itefu::Benchmark以下にあるモジュールの特異メソッドを順に呼び出す
  def self.run
    Itefu::Benchmark.constants.each do |symbol|
      const = Itefu::Benchmark.const_get(symbol)
      const.singleton_methods(false).each do |method|
        const.send(method)
      end if const.is_a?(Module)
    end
  rescue RGSSReset
  end

  # GCをオフにして計測するための設定
  class GCSuite
    def warming(*)
      run_gc
    end
  
    def running(*)
      run_gc
    end
  
    def warmup_stats(*)
    end
  
    def add_report(*)
    end
  
  private
  
    def run_gc
      GC.enable
      GC.start
      GC.disable
    end
  end
  @@gc_suite = GCSuite.new
  def self.gc_suite; @@gc_suite; end

end
