=begin
  キーフレームアニメーション
=end
class Itefu::Animation::KeyFrame < Itefu::Animation::Base
  PROC_TO_RETURN_FRAME = proc {|data| data[:frame] }

  # [Boolean] offset_modeが設定されていない要素の値を計算するときに参照する
  attr_accessor :default_offset_mode

  # [Object] ターゲットが設定されていない要素を操作する際の対象になる
  attr_accessor :default_target   
  def context; self.default_target; end
  def context=(v); self.default_target = v; end

  attr_reader :max_frame_count  # [Fixnum] アニメのフレーム数

  def on_initialize
    @keys = {}
    @initials = {}        # elementごとの初期値
    @max_frame_count = 0  # アニメーションの長さ
  end

  # DSL風に記述するためのメソッド
  module DSL
    def loop(value); @looping = value; end
    def default_curve(value); @default_curve = value; end
    def offset_mode(element, value)
      @offset_mode ||= {}
      @offset_mode[element] = value
    end
    def assign_target(element, value)
      @targets ||= {}
      @targets[element] = value
    end
    def max_frame(value); @max_frame_count = value; end

    # 再生速度を設定する
    # @param [Fixnum] value 再生速度
    # @param [Fixnum] denominator 指定した場合はvalue/denominatorのRationalを設定する
    def speed(value, denominator = nil)
      if denominator
        @play_speed = Rational(value, denominator)
      else
        @play_speed = value
      end
    end
  end
  include DSL

  # キーを設定する
  # @param [Fixnum] キーを設定するフレーム数
  # @param [Symbol] element 操作する要素
  # @param [Object] value このキーで設定する値, nilでアニメ再生時の初期値を使用する
  # @param [Proc] curve キー間の補完方法, nilでデフォルトを使用する
  def add_key(frame_count, element, value, curve = nil)
    @keys[element] ||= []
    @max_frame_count = Itefu::Utility::Math.max(frame_count, @max_frame_count)
    
    Itefu::Utility::Array.insert_to_sorted_array({
      frame: frame_count,
      value: value,
      curve: curve,
    }, @keys[element], &PROC_TO_RETURN_FRAME)
  end

  # トリガーを設定する
  # @note トリガーは 指定したフレーム数を通過した際に一度だけ呼ばれる
  def add_trigger(frame_count, &block)
    return unless block
    @triggers ||= []
    @max_frame_count = Itefu::Utility::Math.max(frame_count, @max_frame_count)

    Itefu::Utility::Array.insert_to_sorted_array({
      frame: frame_count,
      proc: block,
    }, @triggers, &PROC_TO_RETURN_FRAME)
  end
  
  # 再生開始
  def on_start(player)
    @prev_frame_count = -1
    @initials.clear
    @keys.each_key do |element|
      @initials[element] = initial_value(@targets && @targets[element] || @default_target, element)
    end
  end
  
  # 再生終了
  def on_finish
    # アニメの最後のフレームの状態に合わせて終わる
    update_keyframe_animations(@max_frame_count)
  end
  
  # 更新
  def on_update(delta)
    if @play_count >= @max_frame_count
      if @looping
        # 最後のフレームと最初のフレームが同一になる
        @play_count = 0
      else
        # finishで最後の状態に合わせられるので、更新を行わずにぬける
        return finish
      end
    end

    update_keyframe_animations(@play_count)
    @prev_frame_count = @play_count
  end


private

  # 指定したフレームに適合するアニメーション処理を行う
  # @param [Numeric] frame_count 再生フレーム数
  def update_keyframe_animations(frame_count)
    update_keyframe_triggers(frame_count)

    @keys.each do |element, keyframes|
      index_end = Itefu::Utility::Array.upper_bound(frame_count, keyframes, &PROC_TO_RETURN_FRAME)
      if index_end > 0
        index_start = index_end - 1
        update_keyframe_animation(element, frame_count, keyframes[index_start], keyframes[index_end])
      end
    end
  end

  # トリガー系の処理を行う
  # @param [Numeric] frame_count 再生フレーム数
  def update_keyframe_triggers(frame_count)
    return unless @triggers
    # 既に処理済のフレームの場合は無視する  (play_speed次第では同じフレームが何度も呼ばれる可能性があるため)
    return if frame_count.to_i == @prev_frame_count.to_i

    # 既に処理済のものをチェック対象にする
    index_to_trigger = Itefu::Utility::Array.upper_bound(@prev_frame_count, @triggers, &PROC_TO_RETURN_FRAME)
    # このフレームで処理できるものを全て呼ぶ
    while (trigger = @triggers[index_to_trigger]) && (trigger[:frame] <= frame_count)
      trigger[:proc].call(self, frame_count, trigger)
      index_to_trigger += 1
    end
  end

  # 要素ごとの処理を行う
  def update_keyframe_animation(element, frame_count, data_start, data_end)
    return unless (target = @targets && @targets[element] || @default_target)
    initial = @initials[element]
    curve = data_start[:curve] || @default_curve || linear
    offset = @offset_mode && @offset_mode.has_key?(element) ? @offset_mode[element] : @default_offset_mode
    sv = offset ? initial + (data_start[:value] || 0) : (data_start[:value].nil? ? initial : data_start[:value])

    if data_end
      ev = offset ? initial + (data_end[:value] || 0) : (data_end[:value].nil? ? initial : data_end[:value])
      # 後ろ側にキーが打ってある場合はその間を補完する
      sf = data_start[:frame]
      ef = data_end[:frame]
      rate = Itefu::Utility::Math.clamp(0.0, 1.0, (frame_count - sf).to_f / (ef - sf))
      value = curve.call(rate, sv, ev)
    else
      # これ以上キーがない場合
      ev = sv
      value = curve.call(0, sv, ev)
    end
    
    # 整数同士の場合、補完後の値も整数にする
    if sv.is_a?(Integer) && ev.is_a?(Integer)
      value = value.to_int
    end

    update_value(target, element, value)
  end

  # 要素の値を更新する
  def update_value(target, element, value)
    target.send(:"#{element}=", value) if target
  rescue RGSSError
  end

  # 要素の値を取得する (初期値の設定用)
  def initial_value(target, element)
    target.send(element)
  end

  # キー間の補完方法
  module CurveFunctions
    LINEAR = lambda {|rate, s, e| s + (e - s) * rate }
    STEP_BEGIN = lambda {|rate, s, e| s }
    STEP_END = lambda {|rate, s, e| e }

    # 二区間を線形に変化させる
    def linear; LINEAR; end
    
    # 二区間のうち開始点の値を使う
    def step; STEP_BEGIN; end
    def step_begin; STEP_BEGIN; end
    
    # 二区間のうち終端の値を使う
    def step_end; STEP_END; end

    # 3次元ベジエ曲線に沿って二区間を変化する
    # @param [Float] x1 始点側ハンドルの x [0.0-1.0]
    # @param [Float] y1 始点側ハンドルの y
    # @param [Float] x2 終点側ハンドルの x [0.0-1.0]
    # @param [Float] y2 終点側ハンドルの y
    # @param [Fixnum] resolution 分解能, bezier3のx軸の値からtを計算する際に2^-(resolution+1)の精度で漸近する
    def bezier(x1, y1, x2, y2, resolution = 9)
      # 時間軸xに対して変化量yだけが変化する関数にするため、ハンドルのxを[0-1]に限定する
      x1 = Itefu::Utility::Math.clamp(0, 1, x1)
      x2 = Itefu::Utility::Math.clamp(0, 1, x2)
      lambda {|rate, s, e|
        t = (rate == 0.0 || rate == 1.0) ? rate : Itefu::Utility::Math.solve_bezier3_for_t(x1, x2, rate, resolution)
        bezier_rate = Itefu::Utility::Math.bezier3(0, y1, y2, 1, t)
        s + (e - s) * bezier_rate
      }
    end
  end
  include CurveFunctions

end
