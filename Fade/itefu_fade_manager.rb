=begin
  画面フェードの管理を行うクラス
=end
class Itefu::Fade::Manager < Itefu::System::Base
  attr_accessor :viewport
  attr_reader :fade_type
  
  # フェードアウト中に再びフェードアウトしようとすると発生する
  class AlreadyFadedException < StandardError; end

  # フェードアウトしていないのにresolveしようとすると発生する
  class NotFadedException < StandardError; end
  
  # フェードの種類
  module FadeType
    NONE = nil
    Itefu::Utility::Module.declare_enumration(self, [
      :DEFAULT,
      :COLOR,
      :TRANSITION
    ])
  end
  
  # @return [Boolean] フェードアウトしているか
  # @note フェード解消し忘れの確認に使う
  def faded_out?
    @fade_type != FadeType::NONE
  end
  
  # @return [Boolean] フェード処理中か
  # @note ブロックしないフェードを処理中か判定するのに使う
  def fading?
    @alpha_delta.nil?.!
  end
  
  # @param [Boolean] フェード時にブロックされるか
  def will_be_blocked?(fade_type = @fade_type)
    fade_type == FadeType::DEFAULT || fade_type == FadeType::TRANSITION
  end

  # フェード状態を解消する
  # @note 種類によってはフェードインが完了するまで処理をブロックする
  # @param [Fixnum] din フェードインする長さを上書きする
  def resolve(din = nil)
    @options[0] = din if din
    case @fade_type
    when FadeType::DEFAULT
      Graphics.frame_reset
      Graphics.fadein(*@options)
    when FadeType::COLOR
      reset_alpha_delta(-@options[0])
    when FadeType::TRANSITION
      Graphics.frame_reset
      Graphics.transition(*@options)
    when FadeType::NONE
      raise NotFadedException
    else
      raise Itefu::Exception::Unreachable
    end
    @fade_type = FadeType::NONE
  end
  
  # フェードアウトする
  # @param [FadeType] フェードの種類
  def fade_out_with_type(fade_type, *args)
    case fade_type
    when FadeType::DEFAULT
      fade_out(*args)
    when FadeType::COLOR
      fade_out_with_color(*args)
    when FadeType::TRANSITION
      fade_out_with_transition(*args)
    when FadeType::NONE
      raise Itefu::Exception::NotSupported
    else
      raise Itefu::Exception::Unreachable
    end
  end
  
  # 通常のフェードアウトを行う
  # @note フェードアウトが完了するまで処理をブロックする
  def fade_out(dout, din = dout)
    if @fade_type != FadeType::NONE
      raise AlreadyFadedException
    end
    resolve_forcibly
    @options.clear
    @options << din
    Graphics.fadeout(dout)
    Graphics.frame_reset
    @fade_type = FadeType::DEFAULT
  end
  
  # 指定したビューポートを使って、特定の色へとフェードアウトする
  # @note フェード中も処理をブロックしない
  # @note viewportが設定されていない場合は代わりに fade_out を呼ぶ
  def fade_out_with_color(color, dout, din = dout)
    if @fade_type != FadeType::NONE
      raise AlreadyFadedException
    end
    unless viewport = self.viewport
      return fade_out(dout, din)
    end
    resolve_forcibly
    @options.clear
    @options << din
    viewport.color.red   = color.red
    viewport.color.green = color.green
    viewport.color.blue  = color.blue
    reset_alpha_delta(dout)
    viewport.color.alpha = (dout > 0) ? 0 : 255
    @fade_type = FadeType::COLOR
  end
  alias :fade_color :fade_out_with_color
  
  # トランジションを行う
  # @note フェードアウトが完了するまで処理をブロックする
  def fade_out_with_transition(duration, filename = nil, vague = nil)
    if @fade_type != FadeType::NONE
      raise AlreadyFadedException
    end
    resolve_forcibly
    @options.clear
    if vague
      @options.push duration, filename, vague
    elsif filename
      @options.push duration, filename
    else
      @options << duration
    end
    Graphics.freeze
    @fade_type = FadeType::TRANSITION
  end
  alias :transit :fade_out_with_transition

private
  def on_initialize(vp = nil)
    self.viewport = vp
    @fade_type = FadeType::NONE
    @options = []
  end
  
  def on_finalize
    resolve(0) if faded_out?
    @options.clear
    self.viewport = nil
  end
  
  def on_update
    return unless @alpha_delta
    if (viewport = self.viewport)
      c = viewport.color
      c.alpha += @alpha_delta
      case
      when c.alpha <= 0
        c.alpha = 0
        @alpha_delta = nil
      when c.alpha >= 0xff
        c.alpha = 0xff
        @alpha_delta = nil
      end
    else
      @alpha_delta = nil
    end
  end
  
  def viewport=(vp)
    @viewport = Itefu::Rgss3::Resource.swap(@viewport, vp)
  end

private

  def resolve_forcibly
    @alpha_delta = nil
    if (viewport = self.viewport) && viewport.disposed?.!
      viewport.color.alpha = 0
    end
  end
  
  def reset_alpha_delta(duration)
    if duration && duration != 0
      @alpha_delta = 255.0 / duration
    else
      resolve_forcibly
    end
  end

end
