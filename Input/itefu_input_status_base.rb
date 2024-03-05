=begin
  入力デバイスの入浴状態を保持するクラスの基底
=end
class Itefu::Input::Status::Base
  attr_accessor :repeat_wait      # [Float] 押されてからリピートするまでの時間(秒)
  attr_accessor :repeat_interval  # [Float] 押し続けている間のリピート間隔(秒)

  DEFAULT_REPEAT_WAIT = 0.3
  DEFAULT_REPEAT_INTERVAL = 0.1

  module KeyState
    NONE = :none
    TRIGGERED = :triggered
    PRESSED = :pressed
    REPEATED = :repeated
    RELEASED = :released
  end

private
  # optional_values へのアクセッサを定義する
  def self.attr_optional_value(name)
    define_method(name) do
      @optional_values[name]
    end
  end

  # --------------------------------------------------
  # 派生先で実装する

  # @return [Boolean] キーが押されているか
  def press_key?(key_code)
    raise Itefu::Exception::NotImplemented
  end

public
  # --------------------------------------------------
  # Managerから呼ぶメソッド

  # チェックするキーの設定
  # @param [Array<Fixnum>] keys チェックするキーコードの配列
  def setup(keys)
    @key_codes = keys
    @states.clear
    @repeats.clear
  end

  # 割り込みごとの更新
  def update
    @key_codes.each do |code|
      update_key_status(code)
      update_key_repeat(code)
    end
  end

  # @return [Fixnum|NilClass] 任意のオプション値
  # @note デバイスごとに異なる様々な情報を取得する
  def optional_value(name)
    @optional_values[name]
  end

  # @return [Boolean] キーが押されているか
  # @param [Fixnum] code キーコード
  def pressed?(code)
    case @states[code]
    when KeyState::TRIGGERED,
         KeyState::PRESSED,
         KeyState::REPEATED
      true
    else
      false
    end
  end

  # @return [Boolean] いままで押されていなかったキーが入力されたか
  # @param [Fixnum] code キーコード
  def triggered?(code)
    @states[code] == KeyState::TRIGGERED
  end

  # @return [Boolean] いままで押されていたキーが離されたか
  # @param [Fixnum] code キーコード
  def released?(code)
    @states[code] == KeyState::RELEASED
  end

  # @return [Boolean] キーがおされ続けているか
  # @note pressed?な場合に、リピート間隔に応じて定期的にtrueを返す
  # @param [Fixnum] code キーコード
  def repeated?(code)
    case @states[code]
    when KeyState::TRIGGERED,
         KeyState::REPEATED
      true
    else
      false
    end
  end


private
  # --------------------------------------------------
  # 内部実装

  def initialize
    @key_codes = []
    @states = Hash.new(KeyState::NONE)
    @repeats = {}
    @optional_values = {}

    @repeat_wait = DEFAULT_REPEAT_WAIT
    @repeat_interval = DEFAULT_REPEAT_INTERVAL
  end

  # キーの状態を更新する
  def update_key_status(code)
    if press_key?(code)
      if pressed?(code)
        @states[code] = KeyState::PRESSED
      else
        @states[code] = KeyState::TRIGGERED
      end
    else
      if pressed?(code)
        # 今はキーが押されていないが直前までは押されていた
        @states[code] = KeyState::RELEASED
      else
        @states[code] = KeyState::NONE
      end
    end
  end

  # キーの繰り返し入力の状態を更新する
  def update_key_repeat(code)
    if pressed?(code)
      if @repeats[code]
        if Time.now > @repeats[code]
          # 待ち時間だけ待ったので、繰り返し入力状態にする
          @states[code] = KeyState::REPEATED
          @repeats[code] = (Time.now + @repeat_interval)
        end
      else
        # 初回の待ち時間を設定
        @repeats[code] = (Time.now + @repeat_wait)
      end
    else
      @repeats[code] = nil
    end
  end

end
