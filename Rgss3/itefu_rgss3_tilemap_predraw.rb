=begin
  Tilemap::Predrawの拡張
=end
class Itefu::Rgss3::Tilemap::Predraw < Itefu::Tilemap::Predraw
  include Itefu::Rgss3::Resource

  def viewport=(vp)
    super(Itefu::Rgss3::Resource.swap(self.viewport, vp))
  end

  def impl_dispose
    super
    self.viewport = nil
  end
  
  def reset_resource_properties(vp = nil)
    # 使いまわせるかよくわからないのと、需要もないように思えるので、ひとまず未対応としている
    raise Itefu::Exception::NotSupported
  end

end
