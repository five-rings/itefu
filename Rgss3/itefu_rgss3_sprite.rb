=begin
  RGSS3のSpriteの拡張
=end
class Itefu::Rgss3::Sprite < Sprite
  include Itefu::Rgss3::Resource

  module BlendingType
    NORMAL = 0
    ADD = 1
    SUB = 2
  end

  def initialize(vp = nil)
    # @note self.viewport=が呼ばれないので明示的にカウントを上げる
    vp.ref_attach if vp
    super
  end
  
  def clone
    nsp = self.class.new
    nsp.bitmap = self.bitmap
    nsp.src_rect = self.src_rect
    nsp.viewport = self.viewport
    nsp.visible = self.visible
    nsp.x = self.x
    nsp.y = self.y
    nsp.z = self.z
    nsp.ox = self.ox
    nsp.oy = self.oy
    nsp.zoom_x = self.zoom_x
    nsp.zoom_y = self.zoom_y
    nsp.angle = self.angle
    nsp.wave_amp = self.wave_amp
    nsp.wave_length = self.wave_length
    nsp.wave_speed = self.wave_speed
    nsp.wave_phase = self.wave_phase
    nsp.mirror = self.mirror
    nsp.bush_depth = self.bush_depth
    nsp.bush_opacity = self.bush_opacity
    nsp.opacity = self.opacity
    nsp.blend_type = self.blend_type
    nsp.color = self.color
    nsp.tone = self.tone
    nsp
  end

  def bitmap=(bmp)
    super(Itefu::Rgss3::Resource.swap(self.bitmap, bmp))
  end
  
  def viewport=(vp)
    super(Itefu::Rgss3::Resource.swap(self.viewport, vp))
  end
  
  def impl_dispose
    super
    self.viewport = nil
    self.bitmap = nil
  end
  
  def reset_resource_properties(vp = nil)
    self.visible = false
    self.viewport = vp
    # 初期値に戻す
    self.src_rect.empty
    self.x = self.y = self.z = 0
    self.ox = self.oy = 0
    self.zoom_x = self.zoom_y = 1.0
    self.angle = 0
    self.wave_amp = 0
    self.wave_length = 180
    self.wave_speed = 360
    self.wave_phase = 0.0
    self.mirror = false
    self.bush_depth = 0
    self.bush_opacity = 128
    self.opacity = 255
    self.color.set(0, 0, 0, 0)
    self.tone.set(0, 0, 0, 0)
  end

end
