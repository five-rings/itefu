=begin
  デザインパターンのStateパターンのContextクラス
  各ステートで共有するデータとして使う
=end
module Itefu::Utility::State::Context
  attr_reader :state        # [State] 現在のステート
  attr_reader :state_work   # [Object] ステート間で共有して自由に使用できるデータ

  def initial_state_work; {}; end

  def state_idle?; @state == Itefu::Utility::State::DoNothing; end
  def state_on_working?; state_idle?.!; end

  def initialize(*args)
    @state_work = initial_state_work
    @state = Itefu::Utility::State::DoNothing
    super
  end

  # 現在のステートを解除し何もしない状態にする
  def clear_state
    @state.on_detach(self)
    @state = Itefu::Utility::State::DoNothing
  end

  # ステートを切り替える
  # @param [Class] state_klass 遷移したいステート
  # @param [Array<Object>] args on_attachに渡す任意のパラメータ
  def change_state(state_klass, *args)
    @state.on_detach(self)
    @state = state_klass
    state_klass.on_attach(self, *args)
  end

  # 現在のステートの更新処理を呼ぶ
  # @param [Array<Object>] args 任意のパラメータ
  def update_state(*args)
    @state.on_update(self, *args)
  end

  # 現在のステートの描画処理を呼ぶ
  # @param [Array<Object>] args 任意のパラメータ
  def draw_state(*args)
    @state.on_draw(self, *args)
  end

end
