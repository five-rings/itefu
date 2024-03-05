=begin
  RGSS3やそのデフォルト実装で使用している特徴関連の定数
=end
module Itefu::Rgss3::Definition::Feature

  module Code
    # 耐性
    ELEMENT_RATE            = 11    # 属性攻撃への耐性
    DEBUFF_RATE             = 12    # 弱体攻撃への耐性
    STATE_RATE              = 13    # ステータス変更の成功しやすさ
    RESISTED_STATE          = 14    # 無効化されたステータス
    # 能力値
    PARAM                   = 21    # 通常能力値
    XPARAM                  = 22    # 追加能力値
    SPARAM                  = 23    # 特殊能力値
    # 攻撃
    ATTACK_ELEMENT          = 31    # 属性攻撃
    ATTACK_STATE            = 32    # ステータス付与攻撃
    ATTACK_SPEED            = 33    # 攻撃速度補正
    ADDITIONAL_ATTACK_TIMES = 34    # 攻撃追加回数
    # スキル
    ENABLED_SKILL_TYPE      = 41    # 指定したスキルタイプを選べるようにする
    DISABLED_SKILL_TYPE     = 42    # 指定したスキルタイプを選べなくする
    ENABLED_SKILL           = 43    # スキルを追加する
    DISABLED_SKILL          = 44    # スキルを使えなくする
    # 装備
    ENABLED_WEAPON_TYPE     = 51    # 装備できる武器タイプを追加する
    ENABLED_ARMOR_TYPE      = 52    # 装備できる防具タイプを追加する
    FIXED_EQUIPMENT_SLOT    = 53    # 特定箇所の装備を変更できなくする
    SEALED_EQUIPMENT_SLOT   = 54    # 特定箇所に装備できなくする
    EQUIPMENT_SLOT_TYPE     = 55    # 二刀流を設定する
    # その他
    ADDITIONAL_ACTION_RATE  = 61    # 行動回数追加
    SPECIAL_FLAG            = 62    # 特殊フラグを設定
    COLLAPSE_TYPE           = 63    # 消滅エフェクト
    PARTY_ABILITY           = 64    # パーティ能力
  end

 # Code::XPARAM
  module XParam
    HIT_RATE                = 0     # 命中率
    EVASION_RATE            = 1     # 回避率
    CRITICAL_RATE           = 2     # 会心率
    CRITICAL_EVASION_RATE   = 3     # 会心回避率
    MAGIC_EVASION_RATE      = 4     # 魔法回避率
    MAGIC_REFLECTION_RATE   = 5     # 魔法反射率
    COUNTER_ATTACK_RATE     = 6     # 反撃率
    HP_REGENERATION_RATE    = 7     # HP回復率
    MP_REGENERATION_RATE    = 8     # MP回復率
    TP_REGENERATION_RATE    = 9     # TP回復率
  end
  
  # Code::SPARAM
  module SParam
    HATE_RATE               = 0     # 狙われ率
    GUARD_EFFECT_RATE       = 1     # ガード時のダメージ軽減率
    RECOVERY_EFFECT_RATE    = 2     # HP/MPの回復を受けたときの回復率
    PHARMACOLOGY            = 3     # アイテムを使用したときの回復量の値
    MP_CONSUME_RATE         = 4     # スキル使用時のMP消費率
    TP_CHARGE_RATE          = 5     # TP増加率
    PHYSIC_DAMAGE_RATE      = 6     # 物理ダメージを受ける割合
    MAGIC_DAMAGE_RATE       = 7     # 魔法ダメージを受ける割合
    FLOOR_DAMAGE_RATE       = 8     # 床ダメージを受ける割合
    EXP_EARNING_RATE        = 9     # 経験地取得の割合
  end

  # Code::SPECIAL_FLAG
  module SpecialFlag
    AUTO_BATTLE             = 0     # 自動戦闘
    GUARD                   = 1     # 防御
    PROTECT                 = 2     # 身代わり（他のプレイヤーをかばう）
    CARRY_TP_OVER           = 3     # TPを持ち越す
  end
  
  # Code::COLLAPSE_TYPE
  module CollapseType
    NONE                    = 0     # なし
    BOSS                    = 1     # ボス
    INSTANT                 = 2     # 瞬間消去
    INCOLLAPSABLE           = 3     # 消えない
  end

  # Code::PARTY_ABILITY
  module PartyAbility
    ENCOUNTER_HALF          = 0     # エンカウント半減
    ENCOUNTER_NONE          = 1     # エンカウント無効
    CANCEL_SURPRISE         = 2     # 不意打ち無効
    RAISE_PREEMPTIVE        = 3     # 先制攻撃率アップ
    GOLD_DOUBLE             = 4     # 獲得金額二倍
    DROP_ITEM_DOUBLE        = 5     # アイテム入手率二倍
  end

end

