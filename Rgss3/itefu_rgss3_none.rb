=begin
  ダミーのリソース
=end
class Itefu::Rgss3::None
  def dispose; end
  include Itefu::Rgss3::Resource
  alias :disposed? :ref_releaseable?
end
