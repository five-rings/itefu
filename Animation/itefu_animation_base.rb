=begin
  アニメーションの基底クラス
=end
class Itefu::Animation::Base
  attr_accessor :context      # [Object] 再生中に参照できる任意のオブジェクト
  attr_accessor :play_speed   # [Rational] 再生速度, 1が等倍
  attr_accessor :started      # [Proc] 再生開始時に呼ばれる
  attr_accessor :finished     # [Proc] 再生終了時に呼ばれる
  attr_accessor :updated      # [Proc] 再生中に毎回呼ばれる
  attr_reader   :state        # [State] 再生状況
  attr_reader   :play_count   # [Numeric] 再生中のカウンタ

  # アニメの再生に失敗
  class FailedToStartException < StandardError; end

  # 再生状況
  module State
    IDLE    = :idle     # 再生していない
    PLAYING = :playing  # 再生中
    PAUSED  = :paused   # 再生中だがポーズしている
  end

  # インスタンス生成時に一度だけ呼ばれる
  def on_initialize(*args); end
  
  # finalizeを読んだ際に呼ばれる
  def on_finalize; end
  
  # 更新時に毎回呼ばれる
  def on_update(delta); end
  
  # 再生開始時に呼ばれる
  def on_start(player, *args); end
  
  # 再生終了時に呼ばれる
  def on_finish; end
  
  # ポーズした際に呼ばれる
  # @note ポーズ中に再度ポーズした場合は呼ばれない. 再生中からポーズに切り替わったときにだけ呼ばれる.
  def on_pause; end
  
  # 再開した際に呼ばれる
  # @note 再生中に再開しようとした場合は呼ばれない. ポーズ中から再生中に切り替わったときにだけ呼ばれる.
  def on_resume; end

  # @return [Boolean] 再生中か
  # @note ポーズ中も再生中に含まれる
  def playing?; @state != State::IDLE; end
  
  # @return [Boolean] ポーズ中か
  def paused?; @state == State::PAUSED; end
  
  # 再生後に自動的にfinalizeする
  # @return [Animation::Base] レシーバーを返す
  def auto_finalize
    @auto_finalize = true
    self
  end
  
  # contextを設定する
  # @return [Animation::Base] レシーバーを返す
  def with_context(context)
    @context = context
    self
  end

  # startedを設定する
  # @return [Animation::Base] レシーバーを返す
  def starter(&block)
    self.started = block
    self
  end
  
  # finishedを設定する
  # @return [Animation::Base] レシーバーを返す
  def finisher(&block)
    self.finished = block
    self
  end
  
  # updatedを設定する
  # @return [Animation::Base] レシーバーを返す
  def updater(&block)
    self.updated = block
    self
  end
  
  # playerに登録し再生する
  # @param [Itefu::Animation::Player] アニメプレイヤー
  # @param [Symbol] id 再生用の識別子
  # @return [Animation::Base] レシーバーを返す if 再生できたとき
  def play(player, id, *args)
    player.play_animation(id, self, *args)
  end


  def initialize(*args, &block)
    self.play_speed = 1
    @play_count = 0
    @state = State::IDLE
    on_initialize(*args, &block)
  end

  # インスタンスを破棄する前に呼ぶ
  def finalize
    finish
    on_finalize
  end

  # アニメーションを再生する際に呼ぶ
  # @return [Boolean] 再生開始したか
  def start(player, *args)
    return false if playing?
    @state = State::PLAYING
    @play_count = 0
    on_start(player, *args)
    started.call(self, player, *args)  if started
    true
  rescue FailedToStartException
    @state = State::IDLE
    false
  end
  
  # アニメーションを終了する際に呼ぶ
  # @note 外部から突然呼ばれても大丈夫なつくりにすることを推奨する.
  def finish
    return false unless playing?
    @state = State::IDLE
    on_finish
    finished.call(self) if finished
    # @todo インスタンスの生成だけ行いstartされなかったアニメのfinalizeにリソース解放があった際に解放漏れを起こす可能性がある
    finalize if @auto_finalize
  end

  # 再生をポーズ（一時停止）する
  def pause
    if @state == State::PLAYING
      @state = State::PAUSED
      on_pause
    end
  end

  # ポーズ（一時停止）を解除し再生を再開する
  def resume
    if @state == State::PAUSED
      @state = State::PLAYING
      on_resume
    end
  end

  # アニメーションの更新, 毎フレーム呼ぶ
  # @param [Numeric] delta アニメーションをどれだけ進めるか
  # @note 外部から与えられた delta * play_speed の分だけアニメーションを進める
  def update(delta)
    return if @state != State::PLAYING

    on_update(delta)
    updated.call(self, delta) if updated

    @play_count += (delta * play_speed)
  end

end
