=begin
  RGSS3やそのデフォルト実装で使用している方向についての定数
=end
module Itefu::Rgss3::Definition::Direction
  NOP = 0   # そのままの向き

  # 直線移動
  module Orthogonal
    DOWN        = 2   # 下
    LEFT        = 4   # 左
    RIGHT       = 6   # 右
    UP          = 8   # 上
  end
  include Orthogonal
  
  # 斜め移動
  module Diagonal
    LEFT_DOWN   = 1   # 左下
    LEFT_UP     = 7   # 左上
    RIGHT_DOWN  = 3   # 右下
    RIGHT_UP    = 9   # 右上
  end
  include Diagonal

  # @return [Boolean] 方向として正しい値か
  # @param [Fixnum] d チェックする値
  # @param [Boolean] diagonal 斜めを許可するか
  def self.valid?(d, diagonal = false)
    case d
    when DOWN, LEFT, RIGHT, UP
      true
    when LEFT_DOWN, LEFT_UP, RIGHT_DOWN, RIGHT_UP
      diagonal
    else
      false
    end
  end

  # @return [Boolean] 上下左右方向か
  # @param [Fixnum] d チェックする値
  def self.orthogonal?(d)
    case d
    when DOWN, LEFT, RIGHT, UP
      true
    else
      false
    end
  end

  # @return [Boolean] 斜め方向か
  # @param [Fixnum] d チェックする値
  def self.diagonal?(d)
    case d
    when LEFT_DOWN, LEFT_UP, RIGHT_DOWN, RIGHT_UP
      true
    else
      false
    end
  end
  
  # @return [Direction, Direction, Direction] 指定したもの以外の方向をまとめた配列を返す
  # @param [Direction] d 方向
  def self.complements(d)
    case d
    when DOWN
      return LEFT, RIGHT, UP
    when LEFT
      return DOWN, RIGHT, UP
    when RIGHT
      return DOWN, LEFT, UP
    when UP
      return DOWN, LEFT, RIGHT
    when LEFT_DOWN
      return LEFT_UP, RIGHT_DOWN, RIGHT_UP
    when LEFT_UP
      return LEFT_DOWN, RIGHT_DOWN, RIGHT_UP
    when RIGHT_DOWN
      return LEFT_DOWN, LEFT_UP, RIGHT_UP
    when RIGHT_UP
      return LEFT_DOWN, LEFT_UP, RIGHT_DOWN
    end
  end
  
  # @return [Diagonal] 斜め方向を返す
  # @param [Orthogonal] horizontal 左右のどちらか
  # @param [Orthogonal] vertial 上下のどちらか
  def self.to_diagonal(horizontal, vertial)
    case vertical
    when UP
      case horizontal
      when LEFT
        LEFT_UP
      when RIGHT
        RIGHT_UP
      end
    when DOWN
      case horizontal
      when LEFT
        LEFT_DOWN
      when RIGHT
        RIGHT_DOWN
      end
    end
  end

  # @return [Array<Orthogonal>] 縦横で返す
  # @param [Diagonal] dir 斜めの向き
  def self.from_diagonal(dir)
    case dir
    when LEFT_DOWN
      return LEFT, DOWN
    when LEFT_UP
      return LEFT, UP
    when RIGHT_DOWN
      return RIGHT, DOWN
    when RIGHT_UP
      return RIGHT, UP
    else
      [dir]
    end
  end
  
  # @return [Direction] 指定した向きの逆方向を返す
  # @param [Direction] d 元の向き
  def self.opposite(d)
    case d
    when DOWN
      UP
    when UP
      DOWN
    when LEFT
      RIGHT
    when RIGHT
      LEFT
    when LEFT_DOWN
      RIGHT_UP
    when LEFT_UP
      RIGHT_DOWN
    when RIGHT_DOWN
      LEFT_UP
    when RIGHT_UP
      LEFT_DOWN
    end
  end
  
  # @return [Direction] 横方向だけを反転させる
  # @param [Direction] d 元の向き
  def self.flip_horizontally(d)
    case d
    when DOWN
      DOWN
    when UP
      UP
    when LEFT
      RIGHT
    when RIGHT
      LEFT
    when LEFT_DOWN
      RIGHT_DOWN
    when LEFT_UP
      RIGHT_UP
    when RIGHT_DOWN
      LEFT_DOWN
    when RIGHT_UP
      LEFT_UP
    end
  end

  # @return [Direction] 横方向だけを反転させる
  # @param [Direction] d 元の向き
  def self.flip_vertically(d)
    case d
    when DOWN
      UP
    when UP
      DOWN
    when LEFT
      LEFT
    when RIGHT
      RIGHT
    when LEFT_DOWN
      LEFT_UP
    when LEFT_UP
      LEFT_DOWN
    when RIGHT_DOWN
      RIGHT_UP
    when RIGHT_UP
      RIGHT_DOWN
    end
  end
  
  # @return [Direction] 時計周りに90度回転させた方向を返す
  # @param [Direction] d 元の向き
  def self.rotate_90_right(d)
    case d
    when DOWN
      LEFT
    when UP
      RIGHT
    when LEFT
      UP
    when RIGHT
      DOWN
    when LEFT_DOWN
      LEFT_UP
    when LEFT_UP
      RIGHT_UP
    when RIGHT_DOWN
      LEFT_DOWN
    when RIGHT_UP
      RIGHT_DOWN
    end
  end
  
  # @return [Direction] 反時計周りに90度回転させた方向を返す
  # @param [Direction] d 元の向き
  def self.rotate_90_left(d)
    case d
    when DOWN
      RIGHT
    when UP
      LEFT
    when LEFT
      DOWN
    when RIGHT
      UP
    when LEFT_DOWN
      RIGHT_DOWN
    when LEFT_UP
      LEFT_DOWN
    when RIGHT_DOWN
      RIGHT_UP
    when RIGHT_UP
      LEFT_UP
    end
  end

  # @return [Direction] ランダムな向き    
  # @param [Boolean] diagonal 斜めを含めるか
  def self.random(diagonal = false)
    if diagonal
      1 + rand(8)
    else
      2 + rand(4) * 2
    end
  end
  
  # @return [Fixnum, Fixnum] 指定した位置の隣x,y座標
  # @param [Fixnum] x 現在位置
  # @param [Fixnum] y 現在位置
  # @param [Direction] d 向いている方向
  # @note d に向き以外の値を渡すと  x, y をそのまま返す
  def self.next(x, y, d)
    case d
    when DOWN
      return x, y+1
    when LEFT
      return x-1, y
    when RIGHT
      return x+1, y
    when UP
      return x, y-1
    when LEFT_DOWN
      return x-1, y+1
    when LEFT_UP
      return x-1, y-1
    when RIGHT_DOWN
      return x+1, y+1
    when RIGHT_UP
      return x+1, y+1
    else
      return x, y
    end
  end
  
  # @return [Boolean] 水平方向への移動か
  # @param [Direction] d 向いている方向
  def self.horizontal?(d)
    case d
    when LEFT, RIGHT
      true
    else
      false
    end
  end
  
  # @return [Boolean] 垂直方向への移動か
  # @param [Direction] d 向いている方向
  def self.vertical?(d)
    case d
    when UP, DOWN
      true
    else
      false
    end
  end
  
  # @return [Direction] 始点sx,syから終点gx,gyへの方向
  # @note 左上0,0で右下に向かうと大きくなる空間で求める
  # @param [Integer] sx 始点の横座標
  # @param [Integer] sy 始点の縦座標
  # @param [Integer] gx 終点の横座標
  # @param [Integer] gy 終点の縦座標
  # @param [Boolean] diagonal 斜め方向の値を返すか
  def self.from_pos(sx, sy, gx, gy, diagonal = false)
    return from_pos_diagonal(sx, sy, gx, gy) if diagonal
    from_distance(gx - sx, gy - sy)
  end

  # @return [Direction] 相対位置を方向に変換したもの
  # @param [Integer] dx 横方向の相対距離
  # @param [Integer] dy 縦方向の相対距離
  def self.from_distance(dx, dy)
    case
    when dx.abs > dy.abs
      case
      when dx < 0
        LEFT
      when dx > 0
        RIGHT
      end
    else
      case
      when dy < 0
        UP
      when dy > 0
        DOWN
      else
        NOP
      end
    end
  end
  
  # @return [Direction] 始点sx,syから終点gx,gyへの方向
  # @note 左上0,0で右下に向かうと大きくなる空間で求める
  # @param [Integer] sx 始点の横座標
  # @param [Integer] sy 始点の縦座標
  # @param [Integer] gx 終点の横座標
  # @param [Integer] gy 終点の縦座標
  def self.from_pos_diagonal(sx, sy, gx, gy)
    from_distance_diagonal(gx - sx, gy - sy)
  end

  # @return [Direction] 相対位置を方向に変換したもの（斜めあり）
  # @param [Integer] dx 横方向の相対距離
  # @param [Integer] dy 縦方向の相対距離
  def self.from_distance_diagonal(dx, dy)
    case
    when dx < 0
      case
      when dy < 0
        LEFT_UP
      when dy > 0
        LEFT_DOWN
      else
        LEFT
      end
    when dx > 0
      case
      when dy < 0
        RIGHT_UP
      when dy > 0
        RIGHT_DOWN
      else
        RIGHT
      end
    else
      case
      when dy < 0
        UP
      when dy > 0
        DOWN
      else
        NOP
      end
    end
  end

end
