=begin
  アニメーションを登録して再生する
=end
module Itefu::Animation::Player
  attr_accessor :animation_speed  # [Rational] 再生速度, 1が等倍

  def initialize(*args)
    self.animation_speed = 1
    @animations = {}
    @reservoir = {}
    super
  end
  
  # 再生中のアニメーションを全て強制的に終了する
  def finalize_animations
    @iterating = true
    @animations.each_value(&:finish)
    @animations.clear
    @iterating = false
    @reservoir.clear
  end

  # アニメーションを再生する
  # @param [Symbol] id 再生用の識別子
  # @param [Animation::Base] アニメーションのインスタンス
  # @param [Array] args startに渡す任意の引数
  # @return [Animation::Base] 再生できた場合は, 再生しはじめたアニメーションのインスタンスを返す
  def play_animation(id, instance, *args)
    return unless instance
    animation(id).finish if playing_animation?(id)

    if @iterating
      # iteration中にhashに追加はできないので遅延再生を行う
      # @todo 同じIDで複数のアニメを予約したときの挙動が曖昧
      # finish を呼んだうえで上書きした方がよさそうだが現状ではstartされていないアニメのfinishを呼んでもなにもしない
      @reservoir[id] = [instance, args]
      instance
    elsif instance.start(self, *args)
      @animations[id] = instance
    end
  end
  
  # @return [Animation::Base] 再生中のアニメーションのインスタンス
  # @param [Symbol] id 再生用の識別子
  def animation(id)
    @animations[id]
  end

  def reserved_animation(id)
    instance = @reservoir[id]
    instance && instance[0]
  end

  # @return [Boolean] アニメーションを再生しているか  
  # @param [Symbol] id 再生用の識別子
  def playing_animation?(id)
    @animations.has_key?(id) && @animations[id].playing?
  end

  # @return [Boolean] 何らかのアニメーションを再生しているか  
  def playing_animations?
    @animations.each_value.any?(&:playing?)
  end

  # 全てのアニメーションを更新する
  def update_animations
    @iterating = true
    @animations.keep_if do |id, animation|
      animation.update(animation_speed)
      animation.playing?
    end
    @iterating = false
    play_reservoir
  end

  # 全てのアニメーションをポーズする
  def pause_animations
    @animations.each_value(&:pause)
  end

  # 全てのアニメーションを再開する
  def resume_animations
    @animations.each_value(&:resume)
  end

private

  # 遅延再生を行う
  def play_reservoir
    @reservoir.each do |id, (instance, args)|
      if instance.start(self, *args)
        @animations[id] = instance
      end
    end
    @reservoir.clear
  end

end
