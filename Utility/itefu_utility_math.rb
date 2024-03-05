=begin
  数学関連の便利機能
=end
module Itefu::Utility::Math

  # ラジアン角
  module Radian
    CIRCLE         = ::Math::PI * 2
    FULL_CIRCLE    = CIRCLE
    HALF_CIRCLE    = ::Math::PI
    QUARTER_CIRCLE = ::Math::PI / 2
  end

  # 角度
  module Degree
    CIRCLE         = 360
    FULL_CIRCLE    = CIRCLE
    HALF_CIRCLE    = 180
    QUARTER_CIRCLE = 90
  end
  
class << self
  
  # @return [Object] [min-max]にクランプした値を返す  
  # @param [Object] min 比較演算子を持つ最小値
  # @param [Object] max 比較演算子を持つ最大値
  # @param [Object] value
  def clamp(min, max, value)
    if value < min
      min
    elsif value > max
      max
    else
      value
    end
  end
 
  # min/max に nil を受け付けるclamp 
  # @return [Object] [min-max]にクランプした値を返す  
  def clamp_with_nil(min, max, value)
    return unless value
    if min && value < min
      min
    elsif max && value > max
      max
    else
      value
    end
  end
  
  # @return [Object] [min-max]を超えた場合ラップして値を返す
  # @param [Object] min 比較演算子を持つ最小値
  # @param [Object] max 比較演算子を持つ最大値
  # @param [Object] value
  def wrap(min, max, value)
    if value < min
      max
    elsif value > max
      min
    else
      value
    end
  end

  # @return [Object] [min-max]を範囲外にも繰り返した場合の値を返す
  # @param [Object] min 加減演算子を持つ最小値
  # @param [Object] max 加減演算子を持つ最大値
  # @oaram [Object] value 剰余演算子を持つ実際の値
  def loop(min, max, value)
    min + (value % (max - min + 1))
  end
  
  # @return [Object] [0-size)を範囲外にも繰り返した場合の値を返す
  # @param [Object] size 範囲を示す離散的な要素数
  # @oaram [Object] value 剰余演算子を持つ実際の値
  def loop_size(size, value)
    value % size 
  end

  # @return [Object] 小さいほうを返す
  # @param [Object] limit 比較演算子を持つ最小値
  # @param [Object] value
  def min(limit, value)
    value > limit ? limit : value
  end

  # @return [Object] 大きいほうを返す
  # @param [Object] limit 比較演算子を持つ最大値
  # @param [Object] value
  def max(limit, value)
    value < limit ? limit : value
  end
  
  # 実引数のうち最小の値を返す
  # @retirm [Object] 最小値を返す
  def min_from(*args)
    args.min
  end

  # 実引数のうち最大の値を返す
  # @retirm [Object] 最大値を返す
  def max_from(*args)
    args.max
  end

  # 乱数を[min-max]の範囲で返す
  # @return [Numeric] 擬似乱数値
  def rand_in(min, max, r = Random)
    min + r.rand(1 + max - min)
  end

  # @return [Float] 三次ベジエ曲線に沿った位置
  # @param [Float] p0 制御点0 (始点)
  # @param [Float] p1 制御点1 (ハンドル1)
  # @param [Float] p2 制御点2 (ハンドル2)
  # @param [Float] p3 制御点3 (終点)
  # @param [Float] t [0.0-1.0]で始点から終点までの位置を計算する
  # @note 二次元座標を求める場合、x, yそれぞれ別にこの関数を適用する
  def bezier3(p0, p1, p2, p3, t)
    # (1-t)**3*p0 + 3*(1-t)**2*t*p1 + 3*(1-t)*t**2*p2 + t**3*p3
    it = (1 - t)
    it2 = it ** 2
    t2 = t ** 2
    p0*it2*it + p1*3*it2*t + p2*3*it*t2 + p3*t2*t
  end

  # @return [Float] 三次ベジエ曲線と点pが交わる場合のtの近似値 (0.0-1.0)
  # @note p0が0, p3が1の場合にのみ適用できる
  # @param [Float] p1 制御点1 (ハンドル1) [0.0-1.0]
  # @param [Float] p2 制御点2 (ハンドル2) [0.0-1.0]
  # @param [Float] p 交点 [0.0-1.0]
  # @param [Fixnum] count 計算回数, 2^-(count+1) の精度で近似値を求める, 処理時間はcountに比例して増える.
  def solve_bezier3_for_t(p1, p2, p, count)
    # 解の公式を用いても小数点の精度による誤差は生じるのと
    # 計算途中で cbrt や sqrt などを使用し決して軽い処理とは言えないこと
    # そもそもそこまで高い精度は求められないことから
    # わかりやすい平易な方法で近似値を求める
    t = 0.5
    div = 0.25
    count.times do
      c = bezier3(0, p1, p2, 1, t)
      if p > c
        t += div
      elsif p < c
        t -= div
      else
        break
      end
      div /= 2
    end
    t
  end

  # 標準シグモイド関数
  # @return [Float]
  # @param [Numeric] x
  def sigmoid(x)
    1.0 / (1.0 + Math.exp(-x))
  end

end

  # Box-Muller法を使った正規乱数生成器
  class NormalRandom

    def self.rand(*args)
      DEFAULT.rand(*args)
    end

    attr_reader :average, :standard_deviation
    attr_reader :unif_rand

    def initialize(avg = nil, sd = nil, rand = nil)
      reset(avg || 0, sd || 1)
      @unif_rand = rand || Random
    end

    # μとσを再設定する
    def reset(avg = nil, sd = nil)
      @average = avg if avg
      @standard_deviation = sd if sd
      @z2 = nil
    end

    # @param [Floag] 正規分布に従って乱数を返す
    # @param [Numeric] avg μを指定する, 省略時は事前設定のものを使う
    # @param [Numeric] sd σを指定する, 省略時は事前設定のものを使う
    def rand(avg = @average, sd = @standard_deviation)
      if @z2
        z1 = @z2
        @z2 = nil
      else
        lnx = -2 * Math.log(@unif_rand.rand)
        py  =  2 * Math::PI * @unif_rand.rand
        z1   = Math.sqrt(lnx) * Math.sin(py)
        @z2  = Math.sqrt(lnx) * Math.cos(py)
      end
      sd * z1 + avg
    end

  private
    DEFAULT = NormalRandom.new
  end

end
