=begin
  RGSS3やそのデフォルト実装で使用しているスキル関連の定数
=end
module Itefu::Rgss3::Definition::Skill
  module Type
    NONE  = 0
    def self.none?(t); t == NONE; end
  end

  module HitType
    INEVITABLE = 0
    PHYSICAL   = 1
    MAGICAL    = 2
  end

  module Scope
    NONE                = 0
    OPPONENT            = 1
    ALL_OPPONENTS       = 2
    RANDOM_1_OPPONENT   = 3
    RANDOM_2_OPPONENTS  = 4
    RANDOM_3_OPPONENTS  = 5
    RANDOM_4_OPPONENTS  = 6
    FRIEND              = 7
    ALL_FRIENDS         = 8
    DEAD_FRIEND         = 9
    ALL_DEAD_FRIENDS    = 10
    MYSELF              = 11

    def self.to_opponent?(scope)
      case scope
      when OPPONENT, ALL_OPPONENTS, RANDOM_1_OPPONENT, RANDOM_2_OPPONENTS, RANDOM_3_OPPONENTS, RANDOM_4_OPPONENTS
        true
      else
        false
      end 
    end

    def self.to_friend?(scope)
      case scope
      when FRIEND, ALL_FRIENDS, DEAD_FRIEND, ALL_DEAD_FRIENDS, MYSELF
        true
      else
        false
      end
    end

    def self.to_singular?(scope)
      case scope
      when NONE, OPPONENT, RANDOM_1_OPPONENT, FRIEND, DEAD_FRIEND, MYSELF
        true
      else
        false
      end
    end

    def self.to_plural?(scope)
      to_single?(scope).!
    end

    def self.to_dead?(scope)
      case scope
      when DEAD_FRIEND, ALL_DEAD_FRIENDS
        true
      else
        false
      end
    end

    # @return [Fixnum] ランダムにいくつ選ぶべきかを返す
    # @note ランダムでないスコープの場合は0を返す
    def self.random_count(scope)
      if scope >= RANDOM_1_OPPONENT &&
         scope <= RANDOM_4_OPPONENTS
        1 + scope - RANDOM_1_OPPONENT
      else
        0
      end
    end
  end

  module Occasion
    ALWAYS   = 0
    IN_BATTLE = 1
    IN_FIELD  = 2
    UNUSABLE  = 3
    
    def self.usable_in_fieldmenu?(occasion)
      case occasion
      when ALWAYS,
           IN_FIELD
        true
      else
        false
      end
    end

    def self.usable_in_battle?(occasion)
      case occasion
      when ALWAYS,
           IN_BATTLE
        true
      else
        false
      end
    end
  end
  
  module Performance
    # @return [Boolean] 攻撃スキルか
    def self.attack?(skill)
      skill && skill.damage.recover?.! && skill.damage.none?.!
    end
    
    # @return [Boolean] 回復スキルか
    def self.recovery?(skill)
      skill && skill.damage.recover?
    end
    
    # @return [Boolean] バフスキルか
    def self.enbuff?(skill)
      skill && recovery?(skill).! && Scope.to_friend?(skill.scope)
    end

    # @return [Boolean] デバフスキルか
    def self.debuff?(skill)
      skill && attack?(skill).! && Scope.to_opponent?(skill.scope)
    end
  end

  # 使用効果
  module Effect
    RECOVER_HP     = 11              # HP 回復
    RECOVER_MP     = 12              # MP 回復
    GAIN_TP        = 13              # TP 増加
    ADD_STATE      = 21              # ステート付加
    REMOVE_STATE   = 22              # ステート解除
    ADD_BUFF       = 31              # 能力強化
    ADD_DEBUFF     = 32              # 能力弱体
    REMOVE_BUFF    = 33              # 能力強化の解除
    REMOVE_DEBUFF  = 34              # 能力弱体の解除
    SPECIAL        = 41              # 特殊効果
    GROW           = 42              # 成長
    LEARN_SKILL    = 43              # スキル習得
    COMMON_EVENT   = 44              # コモンイベント
  end
end

