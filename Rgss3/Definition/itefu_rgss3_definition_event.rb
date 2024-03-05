=begin
  RGSS3やそのデフォルト実装で使用しているイベント関連の定数定義
=end
module Itefu::Rgss3::Definition::Event

  # マップ表示物のID
  module Id
    PLAYER      = -1  # プレイヤー
    THIS_EVENT  = 0   # 「このイベント」

    # @return [Boolean] プレイヤーを意味しているか
    # @param [Fixnum] id 識別子
    def self.player?(id)
      id < 0
    end

    # @return [Boolean] イベントIDを意味しているか
    # @param [Fixnum] id 識別子
    def self.event?(id)
      id >= 0
    end

    # @return [Boolean] 「このイベント」を意味しているか
    # @param [Fixnum] id 識別子
    def self.event_itself?(id)
      id == 0
    end
  end

  # イベント起動タイプ
  module Trigger
    DECIDE          = 0   # 決定
    TOUCH_BY_PLAYER = 1   # プレイヤーから接触
    TOUCH_BY_EVENT  = 2   # イベントから接触
    AUTO_RUN        = 3   # 自動実行
    PARALLEL        = 4   # 並行実行
    
    # @return [Boolean] 自動実行するイベントか
    def self.auto?(trigger)
      trigger == AUTO_RUN || trigger == PARALLEL
    end
  end
  
  # 移動頻度
  module MoveFrequency
    LOWEST  = 1   # 最低頻度
    LOW     = 2   # 低頻度
    NORMAL  = 3   # 通常
    HIGH    = 4   # 高頻度
    HIGHEST = 5   # 最高頻度

    # @return [Fixnum] 何フレームごとに移動するか
    # @param [Fixnum] frequency 移動頻度
    def self.to_frame(frequency)
      30 * (5 - frequency)
    end
  end
  
  # 移動速度
  module Speed
    VERY_SLOW = 1   # 1/8
    MORE_SLOW = 2   # 1/4
    SLOW      = 3   # 1/2
    NORMAL    = 4   # 1
    FAST      = 5   # 2
    MORE_FAST = 6   # 4
  
    # @return [Fixnum] 1フレームに何マス分移動するか
    # @param [Fixnum] speed 移動速度
    def self.to_cell(speed)
      2 ** speed / 256.0
    end
  end
  
  # 表示優先度
  module PriorityType
    UNDERLAY = 0    # プレイヤーの下
    NORMAL   = 1    # プレイヤーと同じ
    OVERLAY = 2    # プレイヤーの上
    
    # @return [Fixnum] Z座標
    def self.to_z(priority_type)
      case priority_type
      when UNDERLAY
        0
      when OVERLAY
        200
      else
        100
      end
    end
  end
  
  # 移動タイプ
  module MoveType
    FIXED    = 0    # 固定
    RANDOM   = 1    # ランダム
    APPROACH = 2    # 近づく
    CUSTOM   = 3    # カスタム
  end
  
  # フェードタイプ
  module FadeType
    NORMAL = 0    # 黒フェード
    WHITE  = 1    # 白フェード
    NONE   = 2    # フェードなし
  end
  
  # 乗り物の種類
  module VehicleType
    BOAT  = 0   # 小型船
    SHIP  = 1   # 大型船
    PLANE = 2   # 飛行船
  end
  
  # 文章の表示
  module Message
    # 背景
    module Background
      NORMAL      = 0   # 通常ウィンドウ
      DARK        = 1   # 背景を暗くする
      TRANSPARENT = 2   # 透明にする
    end
    # 表示位置
    module Position
      TOP     = 0   # 上
      CENTER  = 1   # 中
      BOTTOM  = 2   # 下
    end
  end
  
  # ピクチャの表示
  module Picture
    # 基点
    module Origin
      LEFT_TOP = 0  # 左上
      CENTER   = 1  # 中心
    end
  end
  
  # 天候の種類
  module WeatherType
    NONE  = :none   # なし
    RAIN  = :rain   # 雨
    STORM = :storm  # 嵐
    SNOW  = :snow   # 雪
  end

  # 戦闘時のイベントの実行間隔
  module Span
    BATTLE = 0
    TURN   = 1
    MOMENT = 2
  end
  
  # イベント実行コード内の演算子タイプ
  module Operation
    ADDITION    = 0   # 加算
    SUBTRACTION = 1   # 減算
  end
  
  # イベント実行コード内の被演算子タイプ
  module OperandType
    CONSTANT = 0    # 定数
    VARIABLE = 1    # 変数
  end
 
  module Battle
    module Result
      WIN    = 0    # 勝った
      ESCAPE = 1    # 逃げた
      LOSE   = 2    # 負けた
    end
    module Target
      LAST_CURSOR = -2   # 最後に選択した相手
      RANDOM      = -1   # ランダム
      INDEX_BASE  = 0
      
      # @return [Boolean] 最後に選択したものを意味しているか
      def self.last_cursor?(index)
        index == LAST_CURSOR
      end

      # @return [Boolean] ランダムターゲットを意味しているか
      def self.random?(index)
        index == RANDOM
      end
    end
  end

  module Route
    module Command
      FINISH = 0
      MOVE_DOWN = 1
      MOVE_LEFT = 2
      MOVE_RIGHT = 3
      MOVE_UP = 4
      MOVE_LEFT_DOWN = 5
      MOVE_RIGHT_DOWN = 6
      MOVE_LEFT_UP = 7
      MOVE_RIGHT_UP = 8
      MOVE_RANDOM = 9
      MOVE_TOWARD_PLAYER = 10
      MOVE_AWAY_FROM_PLAYER = 11
      MOVE_FORWARD = 12
      MOVE_BACK = 13
      JUMP = 14
      WAIT = 15
      TURN_DOWN = 16
      TURN_LEFT = 17
      TURN_RIGHT = 18
      TURN_UP = 19
      TURN_90_RIGHT = 20
      TURN_90_LEFT = 21
      TURN_180 = 22
      TURN_90_RANDOM = 23
      TURN_RANDOM = 24
      TURN_TOWARD_PLAYER = 25
      TURN_AWAY_FROM_PLAYER = 26
      SWITCH_ON = 27
      SWITCH_OFF = 28
      CHANGE_MOVE_SPEED = 29
      CHANGE_MOVE_FREQUENCY = 30
      WALK_ANIME_ON = 31
      WALK_ANIME_OFF = 32
      STEP_ANIME_ON = 33
      STEP_ANIME_OFF = 34
      DIRECTION_FIX_ON = 35
      DIRECTION_FIX_OFF = 36
      THROUGH_ON = 37
      THROUGH_OFF = 38
      TRANSPARENT_ON = 39
      TRANSPARENT_OFF = 40
      CHANGE_GRAPHIC = 41
      CHANGE_OPACITY = 42
      CHANGE_BLENDING_METHOD = 43
      PLAY_SE = 44
      SCRIPT = 45
    end
  end

  # イベント実行コード
  module Code
    SHOW_MESSAGE = 101
    SHOW_CHOICES = 102
    SHOW_NUMERIC_INPUT = 103
    SHOW_ITEM_SELECT = 104
    COMMENT = 108
    BRANCH = 111
    BREAK_LOOP = 113
    ABORT_EVENT = 115
    COMMON_EVENT = 117
    LABEL = 118
    JAMP_TO_LABEL = 119
    CHANGE_GLOBAL_SWITCH = 121
    CHANGE_VARIABLE = 122
    CHANGE_SELF_SWITCH = 123
    TIMER = 124
    ADD_MONEY = 125
    ADD_ITEM = 126
    ADD_WEAPON = 127
    ADD_ARMOR = 128
    CHANGE_MEMBER = 129
    CHANGE_SAVE_PROHIBITION = 134
    CHANGE_MENU_PROHIBITION = 135
    CHANGE_ENCOUNTABLE = 136
    MAP_TRANSFER = 201
    VEHICLE_POSITION = 202
    EVENT_POSITION = 203
    MAP_SCROLL = 204
    ROUTE = 205
    GET_VEHICLE_ON_OFF = 206
    PLAYER_TRANSPARENT = 211
    ANIMATION = 212
    SHOW_BALOON = 213
    ERASE_EVENT = 214

    START_BATTLE = 301
    OPEN_SHOP = 302
    MESSAGE_SEQUEL = 401
    SCROLLING_TEXT_SEQUEL = 405
    COMMENT_SEQUEL = 408
    LOOP_END = 413
    SHOP_SEQUEL = 605
    SCRIPT_SEQUEL = 655
  end

end

