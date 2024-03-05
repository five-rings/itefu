=begin
  Layoutシステム/コレクションを監視可能なオブジェクト
=end
class Itefu::Layout::ObservableCollection
  include Itefu::Layout::Observable
  
  def [](index)
    @value && @value[index]
  end
  
  def []=(index, value)
    # @note 既に設定されているのと同じ値が設定されていた場合、converterによっては結果が変わるものがあるかもしれないので、同値判定は通知先に委譲する
    changed_apparently = (@value[index] != value)
    @value[index] = value
    notify_changed_value(changed_apparently)
  end

end
