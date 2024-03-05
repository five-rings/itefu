=begin
  RGSS3やそのデフォルト実装で使用しているステート関連の定数
=end
module Itefu::Rgss3::Definition::State
  DEAD = 1

  module AutoRemovalTiming
    NONE    = 0    # 自動解除なし
    ACTION  = 1    # 行動終了後
    TURN    = 2    # ターン終了後
  end
  
  module Restriction
    NONE                = 0   # なし
    ATTACK_TO_OPPONENT  = 1   # 敵を攻撃する
    ATTACK_TO_SOMEONE   = 2   # 敵か味方を攻撃する
    ATTACK_TO_FRIEND    = 3   # 味方を攻撃する
    UNMOVABLE           = 4   # 行動できない

    # @return [Boolean] 行動不能か
    def self.unmovable?(res)
      res == UNMOVABLE
    end

    # @return [Boolean] 自動的に攻撃するか
    def self.upset?(res)
      res == ATTACK_TO_OPPONENT ||
        res == ATTACK_TO_SOMEONE ||
        res == ATTACK_TO_FRIEND
    end

    # @return [Boolean] 味方に攻撃する可能性があるか
    def self.confused?(res)
      res == ATTACK_TO_SOMEONE ||
        res == ATTACK_TO_FRIEND
    end

    # @return [Boolean] 操作不能か
    def self.uncontrollable?(res)
      res != NONE
    end
  end

end

