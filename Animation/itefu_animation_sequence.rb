=begin
  既存の複数のアニメを連続して再生する
=end
class Itefu::Animation::Sequence < Itefu::Animation::Base
  attr_reader :playing_index

  # アニメを追加する
  # @note 個々のアニメのインスタンスは外部で管理する
  def add_animation(anime)
    @animations << anime
    anime
  end

  def on_initialize
    @animations = []
    @playing_index = -1
  end

  def on_finalize
    @animations.clear
    @player = nil
  end

  def on_start(player, next_index = 0, *args)
    on_finish
    @player = player
    @playing_index = next_index - 1
    play_next_animation
  end

  def on_finish
    if @anime_playing
      @anime_playing.finish
      @anime_playing = nil
      @playing_index = -1
    end
  end

  def on_pause
    @anime_playing.pause if @anime_playing
  end
  
  def on_resume
    @anime_playing.resume if @anime_playing
  end

  def on_update(delta)
    return unless @anime_playing

    if @anime_playing.playing?
      @anime_playing.update(delta)
    else
      play_next_animation
    end
  end

private

  def play_next_animation(*args)
    @playing_index += 1
    @anime_playing = @animations[@playing_index]
    if @anime_playing
      @anime_playing.start(@player, *args)
    else
      finish
    end
  end

end

