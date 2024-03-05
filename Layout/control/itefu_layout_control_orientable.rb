=begin
  Layoutシステム/内容を並べる方向を選べるコントロールにmix-inする
=end
module Itefu::Layout::Control::Orientable
  include Itefu::Layout::Definition
  extend Itefu::Layout::Control::Bindable::Extension
  attr_bindable :orientation

  def default_orientation; Orientation::HORIZONTAL; end

  def initialize(*args)
    super
    self.orientation = default_orientation
  end

private
  def orientation_storategy
    orientation == Itefu::Layout::Definition::Orientation::HORIZONTAL ? Horizontal : Vertical
  end
  
=begin
  Orientableでは進行方向を持つ.
  座標については, 進行方向を phase, 直交方向を offset とする.
  幅については, 進行方向をを length, 直交方向を amplitude とする. 
  通常の座標系を xywh と書き、上記の座標系を pola と書く.
=end
  
  module Horizontal
    ScreenPhase = :screen_x   # スクリーン座標(進行方向)
    ScreenOffset = :screen_y  # スクリーン座標(垂直方向)
    
    Length = :width           # サイズ（進行方向）
    Amplitude = :height       # サイズ(垂直方向)

    DesiredLength = :desired_width
    DesiredAmplitude = :desired_height

    ContentLength = :content_width
    ContentAmplitude = :content_height
    DesiredContentLength = :desired_content_width
    DesiredContentApmlitude = :desired_content_height
          
    FullLength = :full_width
    FullAmplitude = :full_height
    DesiredFullLength = :desired_full_width
    DesiredFullAmplitude = :desired_full_height

  class << self
    def to_length(width, height);    width;  end  # [Fixnum] width/heightからlengthを取得する
    def to_amplitude(width, height); height; end  # [Fixnum] width/heightからamplitudeを取得する
    def pola_from_xywh(xw, yh); return xw, yh; end
    def xywh_from_pola(pl, oa); return pl, oa; end

    # amp/lenをwidth/heightに変換し, 指定したコントロールのmeasureを呼び出す
    def measure(control, available_length, available_amplitude)
      control.measure(available_length, available_amplitude)
    end

    def arrange(control, phase, offset, length, amplitude)
      control.arrange(phase, offset, length, amplitude)
    end
  end
  end
  
  module Vertical
    ScreenPhase = :screen_y   # スクリーン座標(進行方向)
    ScreenOffset = :screen_x  # スクリーン座標(垂直方向)
    
    Length = :height          # サイズ（進行方向）
    Amplitude = :width        # サイズ(垂直方向)

    DesiredLength = :desired_height
    DesiredAmplitude = :desired_width

    ContentLength = :content_height
    ContentAmplitude = :content_width
    DesiredContentLength = :desired_content_height
    DesiredContentApmlitude = :desired_content_width
    
    FullLength = :full_height
    FullAmplitude = :full_width
    DesiredFullLength = :desired_full_height
    DesiredFullAmplitude = :desired_full_width

  class << self
    def to_length(width, height);    height; end  # [Fixnum] width/heightからlengthを取得する
    def to_amplitude(width, height); width;  end  # [Fixnum] width/heightからamplitudeを取得する
    def pola_from_xywh(xw, yh); return yh, xw; end
    def xywh_from_pola(pl, oa); return oa, pl; end

    # amp/lenをwidth/heightに変換し, 指定したコントロールのmeasureを呼び出す
    def measure(control, available_length, available_amplitude)
      control.measure(available_amplitude, available_length)
    end

    def arrange(control, phase, offset, length, amplitude)
      control.arrange(offset, phase, amplitude, length)
    end
  end
  end

end

