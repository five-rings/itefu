=begin
  Layoutシステム/ViewにMarshal Dumpされたデータからの読込機能を追加する
=end
module Itefu::Layout::View::RvData2
  include Itefu::Layout::View
  LAYOUT_EXTENSION = "dat"
  attr_accessor :layout_path

  def signature_to_layout(signature)
    load_data(signature_to_filename(signature))
  end
  
  def signature_to_filename(signature)
    "#{@layout_path}/#{signature}.#{LAYOUT_EXTENSION}"
  end

end
