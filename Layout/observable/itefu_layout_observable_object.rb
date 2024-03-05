=begin
  Layoutシステム/監視可能なオブジェクト
=end
class Itefu::Layout::ObservableObject
  include Itefu::Layout::Observable
  
  # @note コレクションの場合は専用のものに任せる
  def self.new(value)
    case value
    when Array, Hash
      Itefu::Layout::ObservableCollection.new(value)
    else
      super
    end
  end

end
