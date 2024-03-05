=begin
  関数関連の便利機能
=end
module Itefu::Utility::Function
class << self

  # ブロックを再帰可能な形で呼び出せるようにする
  #
  # @return [Proc] if args.empty?
  # @note recursive {|f,n| n > 1 ? n + f.(n-1) : 1} のようにすると、nを仮引数とするlambdaを得る
  #
  # @return [Object] unless args.empty?
  # @note recursive(10) {|f,n| n > 1 ? n + f.(n-1) : 1} のようにすると、指定した実引数をnに与えてブロックを実行する
  def recursive(*args)
    # 通常はZコンビネータを使うところだろうが再帰をするだけならこれで十分かつ呼び出しコストもこちらの方が小さい
    f = lambda {|*a|
      yield(f, *a)
    }
    args.empty? ? f : f.call(*args)
  end

end  
end
