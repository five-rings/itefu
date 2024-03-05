=begin
  複数のアニメを同時に再生するアニメーションを定義する
=end
class Itefu::Animation::Composite < Itefu::Animation::Base

  # アニメを追加する
  # @param [Class] klass Animations::Baseを継承したクラスの型
  # @param [ARray] args klassをnewする際に渡す任意の引数
  # @return [Animation::Base] 生成したアニメのインスタンス
  # @note ここで生成したインスタンスはこのクラスが破棄するので外部では生存管理をしなくて良い
  def add_animation(klass, *args, &block)
    anime = klass.new(*args, &block)
    @animations << anime
    anime
  end

  def on_initialize
    @animations = []
  end
  
  def on_finalize
    @animations.each(&:finalize)
    @animations.clear
  end
  
  def on_start(player, *args)
    @animations.each {|anime| anime.start(player, *args) }
  end
  
  def on_finish
    @animations.each(&:finish)
  end
  
  def on_pause
    @animations.each(&:pause)
  end
  
  def on_resume
    @animations.each(&:resume)
  end

  def on_update(delta)
    @animations.each {|anime| anime.update(delta) }
    if @animations.none? {|anime| anime.playing? }
      finish
    end
  end

end
