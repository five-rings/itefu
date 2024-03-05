=begin
  RPG Makerのデフォルト実装でSprite_Battlerに実装されているアニメーション
=end
class Itefu::Animation::Battler < Itefu::Animation::Base
  attr_accessor :sprite       # [Itefu::Rgss3::Sprite] 操作対象のSprite
  attr_accessor :effect_type  # [Symbol] 未指定の場合に使用する演出
  attr_accessor :restore      # [Boolean] 再生終了後、表示設定以外を再生前に戻すか

  # エフェクトの種類
  module EffectType
    APPEAR            = :appear             # 現れる
    DISAPPEAR         = :disappear          # 消える
    WHITEN            = :whiten             # 白く光る
    BLINK             = :blink              # 点滅する
    COLLAPSE          = :collapse           # 消滅する
    BOSS_COLLAPSE     = :boss_collapse      # 激しい演出で消滅する
    INSTANT_COLLAPSE  = :instant_collapse   # 一瞬で消滅する
  end

  def on_initialize(effect_type = nil)
    @effect_type = effect_type if effect_type
    @duration = 0
    @visibility = false
    @updater = nil
  end
  
  def on_start(player, effect_type = nil)
    case effect_type || @effect_type
    when EffectType::APPEAR
      @duration = 16
      @visibility = true
      @updater = :update_effect_appear
    when EffectType::DISAPPEAR
      @duration = 32
      @visibility = false
      @updater = :update_effect_disappear
    when EffectType::WHITEN
      @duration = 16
      @visibility = true
      @updater = :update_effect_whiten
    when EffectType::BLINK
      @duration = 20
      @visibility = true
      @updater = :update_effect_blink
    when EffectType::COLLAPSE
      @duration = 48
      @visibility = false
      @updater = :update_effect_collapse
    when EffectType::BOSS_COLLAPSE
      if sprite && sprite.bitmap
        @duration = sprite.bitmap.height
        @visibility = false
        @base_ox = sprite.ox
        @updater = :update_effect_boss_collapse
      else
        @updater = nil
        return false
      end
    when EffectType::INSTANT_COLLAPSE
      @duration = 16
      @visibility = false
      @updater = :update_effect_instant_collapse
    else
      @updater = nil
      return false
    end
    
    store_sprite_data if restore
  end
  
  def on_update(delta)
    self.send(@updater, @play_count.to_i) if sprite

    if @play_count >= @duration
      sprite.visible = @visibility if sprite
      finish
    end
  end
  
  def on_finish
    restore_sprite_data if restore
  end

  # 演出再生前の状態を保持するための型
  SpriteData = Struct.new(:blend_type, :color, :opacity, :y, :ox)

  # エフェクトを再生し始める前の状態にする
  # @return [Itefu::Rgss3::Sprite] レシーバー自身を返す
  def restore_sprite_data
    if @sprite_data
      if sprite
        sprite.blend_type = @sprite_data.blend_type
        sprite.color.set(@sprite_data.color)
        sprite.opacity = @sprite_data.opacity
        sprite.src_rect.y = @sprite_data.y
        sprite.ox = @sprite_data.ox
      end
      clear_sprite_data
    end
    self
  end

  # SpriteDataを捨てる  
  # @return [Itefu::Rgss3::Sprite] レシーバー自身を返す
  def clear_sprite_data
    @sprite_data = nil
    self
  end
  
  # SpriteDataに現在の状態を記録する
  # @note 演出を連続で呼んだときなどを考慮し, 既にSpriteDataが無いときにだけ記録する.
  #       強制的に記録させたい場合は, 先に clear_sprite_data を呼ぶこと.
  # @return [Itefu::Rgss3::Sprite] レシーバー自身を返す
  def store_sprite_data
    @sprite_data ||= SpriteData.new(
      sprite.blend_type,
      sprite.color.clone,
      sprite.opacity,
      sprite.src_rect.y,
      sprite.ox) if sprite
    self
  end

private
  def update_effect_appear(count)
    sprite.opacity = count * 16
  end
  
  def update_effect_disappear(count)
    sprite.opacity = 256 - count * 10
  end
  
  def update_effect_whiten(count)
    sprite.color.set(Itefu::Rgss3::Definition::Color.Whitening)
    sprite.color.alpha = 128 - count * 10
  end
  
  def update_effect_blink(count)
    sprite.opacity = ((@duration - count) % 10 < 5) ? 255 : 0
  end
  
  def update_effect_collapse(count)
    sprite.blend_type = Itefu::Rgss3::Sprite::BlendingType::ADD
    sprite.color.set(Itefu::Rgss3::Definition::Color.Collapsing)
    sprite.opacity = 256 - count * 6
  end
  
  def update_effect_boss_collapse(count)
    d = @duration - count
    sprite.blend_type = Itefu::Rgss3::Sprite::BlendingType::ADD
    sprite.opacity = d * 120 / sprite.bitmap.height
    sprite.color.set(Itefu::Rgss3::Definition::Color.BossCollapsing)
    sprite.color.alpha = 255 - sprite.opacity
    sprite.src_rect.y -= 1
    sprite.ox = @base_ox + d % 2 * 4 - 2
    Itefu::Sound.play_boss_collapse2_se rescue nil if count == 1
  end
  
  def update_effect_instant_collapse(count)
    sprite.opacity = 0
  end
  
end
