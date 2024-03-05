=begin
  Itefu::Utilityの処理に関する速度計測を行う
=end
module Itefu::Benchmark::Utility
class << self

  # ソートしながら追加していくのと、追加してからソートするののどちらが早いかを
=begin
  # 結論: 最後にまとめてソートした方が圧倒的に速い
Calculating -------------------------------------
       push and sort   248.000  i/100ms
insert keepping sorted  32.000  i/100ms
-------------------------------------------------
       push and sort      2.451k (±10.1%) i/s -     12.400k
insert keepping sorted  330.001  (± 8.2%) i/s -      1.664k                       
=end
  def test_add_keeping_sorted
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("push and sort") do
        data = []
        1000.times do
          data.push rand(100)
        end
        data.sort!
      end
      x.report("insert keepping sorted") do
        data = []
        1000.times do
          Itefu::Utility::Array.insert_to_sorted_array(rand(100), data)
        end
      end
    end
  end

  # 置換する際の部分マッチングとマッチした文字列全体の速度差を計測する
  def test_matching_vs_word
=begin
  # ブロック変数で受け取った方が環境変数を使うよりわずかに速い
Calculating -------------------------------------
     camel {|word| }    44.689k i/100ms
        camel { $1 }    42.288k i/100ms
     Upper {|word| }    45.041k i/100ms
        Upper { $1 }    43.113k i/100ms
-------------------------------------------------
     camel {|word| }    882.304k (± 9.9%) i/s -      4.380M
        camel { $1 }    842.445k (±12.0%) i/s -      4.144M
     Upper {|word| }    925.645k (±10.1%) i/s -      4.594M
        Upper { $1 }    862.728k (±10.3%) i/s -      4.268M
=end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("camel {|word| }") do
        STRING_camelCase.sub(/^./) {|word| word.upcase }
      end
      x.report("camel { $1 }") do
        STRING_camelCase.sub(/^(.)/) { $1.upcase }
      end
      x.report("Upper {|word| }") do
        STRING_UpperCamelCase.sub(/^./) {|word| word.upcase }
      end
      x.report("Upper { $1 }") do
        STRING_UpperCamelCase.sub(/^(.)/) { $1.upcase }
      end
    end
  end
 
  # 何もしないブロックを呼ぶのと条件分岐をするのとどちらが早いか計測する
  def test_call_empty_block_vs_branching
=begin
  # 結論1: blockを呼ばないのであれば、分岐した方が圧倒的に速い
  # 結論2: blockを受け取って分岐した方が、block_given?より速い
Calculating -------------------------------------
      block ||= PROC   350.000  i/100ms
            if block   810.000  i/100ms
     if block_given?   619.000  i/100ms
-------------------------------------------------
      block ||= PROC      3.565k (± 8.9%) i/s -     17.850k
            if block      8.202k (± 8.9%) i/s -     41.310k
     if block_given?      6.310k (± 8.6%) i/s -     31.569k
=end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("block ||= PROC") do
        call_empty_block(100)
      end
      x.report("if block") do
        call_block_with_blanching(100)
      end
      x.report("if block_given?") do
        call_with_blanching(100)
      end
    end
  end

  # ブロックを呼ぶ際に分岐するのと何もしないブロックを呼ぶ場合の速度を計測する
  def test_call_block_vs_branching
=begin
  # 結論1: block_given?での分岐が最速
  # 結論2: 確実にblockがあるのであれば、分岐しない方が（当然だが）速い
Calculating -------------------------------------
      block ||= PROC   346.000  i/100ms
            if block   344.000  i/100ms
     if block_given?   449.000  i/100ms
-------------------------------------------------
      block ||= PROC      3.547k (± 3.0%) i/s -     17.992k
            if block      3.443k (± 5.3%) i/s -     17.544k
     if block_given?      4.418k (±10.3%) i/s -     22.001k
=end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("block ||= PROC") do
        call_empty_block(100) {|v| v * 2}
      end
      x.report("if block") do
        call_block_with_blanching(100) {|v| v * 2}
      end
      x.report("if block_given?") do
        call_with_blanching(100) {|v| v * 2}
      end
    end
  end


private
  STRING_camelCase = "testString"
  STRING_UpperCamelCase = "TestString"
  PROC_EMPTY = proc {|v| v }

  def call_empty_block(v, &block)
    block ||= PROC_EMPTY
    1000.times do
      a = block.call(v)
    end
  end

  def call_block_with_blanching(v, &block)
    1000.times do
      if block
        a = block.call(v)
      else
        a = v
      end
    end
  end
  
  def call_with_blanching(v)
    1000.times do
      if block_given?
        a = yield(v)
      else
        a = v
      end
    end
  end

end
end
