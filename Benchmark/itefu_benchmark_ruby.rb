=begin
  rubyの処理系に関する速度計測を行う
=end
module Itefu::Benchmark::Ruby
class << self
  
  # 配列から配列を除外する方法の比較
=begin
  # 結論1: 要素が増えれば増えるほど Array#- を使った方が圧倒的に速い
  # 結論2: 10個のArrayから5個削除するだけでも Array#- の方が速いので、N個削除する際はArray#-を使った方がよい
Calculating 1000 --------------------------------
                   -   518.000  i/100ms
              delete     2.000  i/100ms
           delete_if     4.000  i/100ms
          delete_if2     5.000  i/100ms
-------------------------------------------------
                   -      7.696k (± 5.0%) i/s -     38.850k
              delete     35.483  (± 5.6%) i/s -    178.000 
           delete_if     42.026  (± 4.8%) i/s -    212.000 
          delete_if2     54.968  (± 1.8%) i/s -    275.000   
Calculating   10 --------------------------------
                   -    22.464k i/100ms
              delete    10.014k i/100ms
           delete_if    13.595k i/100ms
          delete_if2    17.249k i/100ms
-------------------------------------------------
                   -    422.386k (± 4.8%) i/s -      2.112M
              delete    204.244k (± 6.2%) i/s -      1.021M
           delete_if    195.269k (± 5.8%) i/s -    978.840k
          delete_if2    209.560k (± 7.4%) i/s -      1.052M
=end
  def test_array_remove
    Benchmark.ips do |x|
      data = 1000.times.map {|i| i }
      to_remove = data.select.with_index {|d, i| i % 2 == 0 }
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("-") do
        d = Array.new(data)
        r = Array.new(to_remove)
        d = d - r
      end
      x.report("delete") do
        d = Array.new(data)
        r = Array.new(to_remove)
        r.each do |rd|
          d.delete(rd)
        end
      end
      x.report("delete_if") do
        d = Array.new(data)
        r = Array.new(to_remove)
        d.delete_if do |dd|
          r.include?(dd)
        end
      end
      x.report("delete_if2") do
        d = Array.new(data)
        r = Array.new(to_remove)
        d.delete_if do |dd|
          r.delete(dd)
        end
      end
    end
  end

  # Arrayに要素を追加するときのpushと<<の速度差
=begin
  # 結論1: << の方がわずかにだが速い
  # 結論2: 同時に複数の要素を追加する場合はpushの方が有利になる
  # array.cを見ると、pushは可変長引数を積んでwhileでまわしているので、その分だけ遅い 
  # 複数要素を追加する場合は、事前処理が一度しか行われないので、同時に追加する要素数が多いほど、pushの方が有利になる
  # それ以外の違い、たとえば << にだけ最適化が施されているということはない
Calculating -------------------------------------
                push   404.000  i/100ms
                  <<   480.000  i/100ms
-------------------------------------------------
                push      6.295k (± 8.0%) i/s -     31.512k
                  <<      7.839k (± 5.9%) i/s -     39.360k
Calculating -------------------------------------
               push2   575.000  i/100ms
                 <<2   557.000  i/100ms
-------------------------------------------------
               push2      5.811k (± 3.6%) i/s -     29.325k
                 <<2      5.760k (± 4.6%) i/s -     28.964k
=end
  def test_array_push
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("push") do
        a = []
        1000.times {|i| a.push(i) }
      end
      x.report("<<") do
        a = []
        1000.times {|i| a << i }
      end
    end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("push2") do
        a = []
        1000.times {|i| a.push(i, i) }
      end
      x.report("<<2") do
        a = []
        1000.times {|i| a << i << i }
      end
    end
  end

  # Hashにhashを追加するときmerge!と[]=のどちらが速いか
=begin
  # 結論: []= を使った方が速い  
Calculating -------------------------------------
              merge!    45.833k i/100ms
                 []=    51.245k i/100ms
-------------------------------------------------
              merge!      1.752M (± 6.2%) i/s -      8.754M
                 []=      2.876M (± 7.3%) i/s -     14.297M
=end
  def test_merge_hash
    hash_data = Hash.new(1000.times.map {|i| [i, i] })
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("merge!") do
        h = {}
        h.merge!(hash_data)
      end
      x.report("[]=") do
        h = {}
        hash_data.each do |k, v|
          h[k] = v
        end
      end
    end
  end

  # divmodと / % を個別に呼ぶのとではどちらが速いか
=begin
  # 結論: divmodを使うより / % を個別に呼んだほうが速い
Calculating -------------------------------------
                 / %    73.022k i/100ms
              divmod    67.379k i/100ms
-------------------------------------------------
                 / %      3.265M (± 9.0%) i/s -     16.211M
              divmod      2.173M (± 8.6%) i/s -     10.781M
=end
  def test_divmod
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("/ %") do
        div_and_mod
      end
      x.report("divmod") do
        divmod
      end
    end
  end
  
  # each(&:method) と each {|v| v.send(:method) } のどちらが速いか
=begin
  # 結論: each(&:method) の方が倍くらい速い
Calculating -------------------------------------
      each(&:method)     1.201k i/100ms
each {send(:method)}   643.000  i/100ms
-------------------------------------------------
      each(&:method)     12.223k (± 8.7%) i/s -     61.251k
each {send(:method)}      6.476k (± 8.3%) i/s -     32.150k
=end
  def test_each_procize_vs_block
    data = []
    1000.times do
      data.push("x" * rand(10))
    end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("each(&:method)") do
        data.each(&:size)
      end
      x.report("each {send(:method)}") do
        data.each {|v| v.send(:size) }
      end
    end
  end

  # 複数の条件をチェックする際に if と case のどちらが速いか
=begin
  # 結論1: 常にcaseが速い、とくに比較対象をcaseに渡す場合は 
  # 結論2: when節に条件を並べるか、複数のwhen節にわけるかは、誤差程度の違いしかない
Calculating -------------------------------------
        branch by if    68.522k i/100ms
      branch by case    72.680k i/100ms
branch by case_batch    72.315k i/100ms
     branch by case2    67.906k i/100ms
-------------------------------------------------
        branch by if      2.660M (± 8.3%) i/s -     13.225M
      branch by case      3.655M (± 7.9%) i/s -     18.170M
branch by case_batch      3.620M (± 9.7%) i/s -     17.934M
     branch by case2      2.661M (± 8.1%) i/s -     13.242M
=end
  def test_if_vs_case
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("branch by if") do
        branch_by_if(5)
      end
      x.report("branch by case") do
        branch_by_case(5)
      end
      x.report("branch by case_batch") do
        branch_by_case_batch(5)
      end
      x.report("branch by case2") do
        branch_by_case2(5)
      end
    end
  end
  
  # メソッドを二回呼び出すのと配列で返すののどちらが速いか
=begin
  # 結論: 二回メソッドを呼ぶより複数返り値の方が速い
Calculating -------------------------------------
      return value*2    67.033k i/100ms
        return array    70.377k i/100ms
-------------------------------------------------
      return value*2      2.483M (± 8.2%) i/s -     12.334M
        return array      3.066M (± 9.7%) i/s -     15.201M
=end  
  def test_return_array
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("return value*2") do
        f = take_first(10, 20)
        s = take_second(10, 20)
      end
      x.report("return array") do
        f, s = take_both(10, 20)
      end
    end
  end

  # 配列の集計でcollectを挟むかinjectにブロックを与えるかでどちらが速いかを計測する
  def test_collect_vs_inject
=begin
  # 結論: injectにブロックを与えた方が、collectionでオブジェクトを生成するより、速い
GC:on  
Calculating -------------------------------------
             collect   438.000  i/100ms
              inject   645.000  i/100ms
-------------------------------------------------
             collect      4.467k (± 7.1%) i/s -     22.338k
              inject      6.396k (± 8.0%) i/s -     32.250k
=end
    data = []
    1000.times do
      data.push("x" * rand(10))
    end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("collect") do
        sum_with_collect(data)
      end
      x.report("inject") do
        sum_without_collect(data)
      end
    end
  end

  # メソッドに渡したブロックを呼ぶ際の速度を計測する
  def test_block
=begin
GC:on
  # 結論1: yield するほうが call するより速い
  # 結論2: yieldならアドホックなブロックが、callなら事前生成したprocを渡した方が速い
Calculating -------------------------------------
            yield {}    70.831k i/100ms
          yield PROC    69.808k i/100ms
             call {}    51.689k i/100ms
           call PROC    61.959k i/100ms
-------------------------------------------------
            yield {}      2.901M (± 8.6%) i/s -     14.450M
          yield PROC      2.766M (± 9.5%) i/s -     13.752M
             call {}      1.214M (± 7.9%) i/s -      6.099M
           call PROC      1.951M (± 7.8%) i/s -      9.728M
=end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("yield {}") do
        to_yield {|v| v * 2 }
      end
      x.report("yield PROC") do
        to_yield(&MULT_2)
      end
      x.report("call {}") do
        to_call {|v| v * 2 }
      end
      x.report("call PROC") do
        to_call(&MULT_2)
      end
    end
  end
  
  # メソッドに渡されたブロックを別のブロックを受け取るメソッドに渡す際の速度を計測する
  def test_block_wrapper
=begin
  # 結論1: アドホックなブロック内でyieldするよりは、blockを引数として受け取って渡した方が速い   
  # 結論2: yieldならアドホックなブロックが、blockを引数として受け取るなら事前生成したprocを渡した方が速い
Calculating -------------------------------------
 each { yield } w/{}    61.000  i/100ms
each { yield } w/PROC
                        60.000  i/100ms
   each(&block) w/{}    86.000  i/100ms
 each(&block) w/PROC    87.000  i/100ms
-------------------------------------------------
 each { yield } w/{}    613.510  (± 1.0%) i/s -      3.111k
each { yield } w/PROC
                        630.798  (± 2.1%) i/s -      3.180k
   each(&block) w/{}    867.167  (± 1.7%) i/s -      4.386k
 each(&block) w/PROC    877.812  (± 1.1%) i/s -      4.437k
=end
    @array = 10000.times.map(&:to_i)
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("each { yield } w/{}") do
        each_yield {|v| v * 2 }
      end
      x.report("each { yield } w/PROC") do
        each_yield(&MULT_2)
      end
      x.report("each(&block) w/{}") do
        each_block {|v| v * 2}
      end
      x.report("each(&block) w/PROC") do
        each_block(&MULT_2)
      end
    end
  end
  
  # ブロックを受け取るメソッドにブロックを渡さなかったときの処理を計測する
  def test_nil_block
=begin
  # 結論: blockを受け取れるようにするだけで、わずかにだが遅くなる 
Calculating -------------------------------------
            method()    70.086k i/100ms
      method(&block)    69.410k i/100ms
-------------------------------------------------
            method()      4.015M (± 6.7%) i/s -     19.975M
      method(&block)      3.807M (± 3.0%) i/s -     19.018M
=end
    Benchmark.ips do |x|
      x.config(:suite => Itefu::Benchmark.gc_suite)
      x.report("method()") do
        do_nothing
      end
      x.report("method(&block)") do
        do_nothing_with_block
      end
    end
  end


private
  MULT_2 = proc {|v| v * 2 }

  def to_yield
    yield(10)
  end
  
  def to_call(&block)
    block.call(10)
  end
  
  def each_yield
    @array.each {|v| yield(v) }
  end
  
  def each_block(&block)
    @array.each(&block)
  end
  
  def do_nothing
  end
  
  def do_nothing_with_block(&block)
  end

  def sum_with_collect(data)
    data.collect(&:size).inject(0, &:+)
  end
  
  def sum_without_collect(data)
    data.inject(0) {|memo, d| memo + d.size }
  end
  
  def take_first(a, b)
    return a
  end
  
  def take_second(a, b)
    return b
  end
  
  def take_both(a, b)
    return a, b
  end
  
  def branch_by_if(x)
    return false if x == 1
    return false if x == 2
    return false if x == 3
    return false if x == 4
    true
  end
  
  def branch_by_case(x)
    case x
    when 1
      false
    when 2
      false
    when 3
      false
    when 4
      false
    else
      true
    end
  end
  
  def branch_by_case_batch(x)
    case x
    when 1,2,3,4
      false
    else
      true
    end
  end

  def branch_by_case2(x)
    case
    when x <= 1
      false
    when x == 2
      false
    when x == 3
      false
    when x == 4
      false
    else
      true
    end
  end
  
  def div_and_mod
    a = 10 / 3
    b = 10 % 3
    a + b
  end
  
  def divmod
    a, b = 10.divmod(3)
    a + b
  end
  
end
end 
