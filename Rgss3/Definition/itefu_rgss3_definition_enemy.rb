=begin
  RGSS3やそのデフォルト実装で使用している敵関連の定数
=end
module Itefu::Rgss3::Definition::Enemy

  module Action
    module ConditionType
      ALWAYS      = 0
      TURN        = 1
      HP          = 2
      MP          = 3
      STATE       = 4
      PARTY_LEVEL = 5
      SWITCH      = 6
    end
  end

  module DropItem
    module Kind
      NOTHING     = 0
      ITEM        = 1
      WEAPON      = 2
      ARMOR       = 3
    end
  end

end

