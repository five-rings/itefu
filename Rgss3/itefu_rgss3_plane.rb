=begin
  RGSS3のPlaneの拡張
=end
class Itefu::Rgss3::Plane < Plane
  include Itefu::Rgss3::Resource
  
  def initialize(vp = nil)
    # @note self.viewport=が呼ばれないので明示的にカウントを上げる
    vp.ref_attach if vp
    super
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
    self.z = 0
    self.ox = self.oy = 0
    self.zoom_x = self.zoom_y = 1.0
    self.opacity = 255
    self.blend_type = 0
    self.color.set(0, 0, 0, 0)
    self.tone.set(0, 0, 0, 0)
  end
  
end
