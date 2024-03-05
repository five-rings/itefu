=begin
  Layoutシステム/定数定義
=end
module Itefu::Layout::Definition
  # 補助機能
  module Utility; include Itefu::Utility; end
  # 例外
  module Exception; include Itefu::Exception; end

  # ボックスレイアウトシステムのための領域
  # @note 矩形でなく各辺ごとの幅を表現する
  class Box
    attr_accessor :top, :right, :bottom, :left

    def initialize(t, r = nil, b = nil, l = nil)
      set(t, r, b, l)
    end

    # 各辺の幅を設定する
    # @param [Fixnum] t 上辺 
    # @param [Fixnum] r 右辺 
    # @param [Fixnum] b 下辺 
    # @param [Fixnum] l 左辺 
    # @return [Box] レシーバー自身を返す
    # @note 要素を省略することができる.
    #       t:      全要素をtにする
    #       t,r:    上下をt, 左右をrにする
    #       t,r,b:  上をt, 下をb, 左右をrにする
    def set(t, r = nil, b = nil, l = nil)
      @top = t
      @right = r || t
      @bottom = b || t
      @left = l || @right
      self
    end
    
    # @return [Fixnum] 横幅を返す
    def width; @right + @left; end

    # @return [Fixnum] 高さを返す
    def height; @bottom + @top; end

    def inspect; "<Box:0x#{object_id.to_s(16)} @top=#{@top}, @right=#{@right}, @bottom=#{@bottom}, @left=#{@left}>"; end
  end
  Box.const_set(:ZERO, Box.new(0).freeze) # 全要素0のボックス 
  Box.const_set(:TEMP, Box.new(0))    # 一時変数として使用できる
  
  # 矩形
  Rect = Struct.new("Rect", :x, :y, :width, :height)
  
  # 色
  Color = Itefu::Color

  # 色調
  Tone = ::Tone

  # 向き
  Direction = Itefu::Rgss3::Definition::Direction

  # サイズ設定
  module Size
    AUTO = :auto    # 自動計算する際に設定する
    
    # @return [Numeric] 実際にコントロールに設定するサイズを計算して返す
    # @param [Numeric] size 数値, AUTO, または operator * を実装したクラスのインスタンス
    # @param [Fixnum] max 最大サイズ
    # @param [Fixnum] 自動で合わせるサイズ, nilならmaxになる
    def self.to_actual_value(size, max, auto = max)
      value = case size
              when AUTO
                # 自動的にサイズを合わせる
                auto
              when Integer
                # 整数はそのまま使用する
                size
              else
                # 特殊な値の場合は operator * を呼び出す
                size * max
              end
      # 負のサイズの場合は, 最大サイズから引いた数として扱う
      value < 0 ? max + value : value
    end
  end

  # コントロールの整列方法
  module Alignment
    LEFT      = :left_top       # 左寄せ (上寄せと共通)
    RIGHT     = :right_bottom   # 右寄せ (下寄せと共通)
    TOP       = :left_top       # 上寄せ(左寄せと共通)
    BOTTOM    = :right_bottom   # 下寄せ(右寄せと共通)
    CENTER    = :center         # 中央寄せ
    STRETCH   = :stretch        # 親コントロールのサイズに合わせる
  end

  # コントロールを並べる方向
  module Orientation
    HORIZONTAL  = :horizontal   # 水平方向に並べる
    VERTICAL    = :vertical     # 垂直方向に並べる
  end
  
  # 表示設定
  module Visibility
    VISIBLE     = :visible      # 表示する
    COLLAPSED   = :collapsed    # 表示しない
    HIDDEN      = :hidden       # 表示しないが場所は占有する

    # @return [Boolean] 画面に表示するか
    def self.visible?(v); v == VISIBLE; end
    
    # @return [Boolean] 場所を占有するか
    def self.takes_space?(v); v != COLLAPSED; end
     
    # @return [Symbol] booleanから変換する
    def self.from_boolean(v); v ? VISIBLE : HIDDEN; end
  end

  # 選択操作
  module Operation
    DECIDE        = :decide
    CANCEL        = :cancel
    MOVE_LEFT     = :move_left
    MOVE_RIGHT    = :move_right
    MOVE_UP       = :move_up
    MOVE_DOWN     = :move_down
    MOVE_POSITION = :move_position
  end

end
