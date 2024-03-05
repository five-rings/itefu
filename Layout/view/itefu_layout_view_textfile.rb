=begin
  Layoutシステム/Viewにテキストファイルからの読込機能を追加する
=end
module Itefu::Layout::View::TextFile
  include Itefu::Layout::View
  LAYOUT_EXTENSION = "rb"
  attr_accessor :layout_path

  def signature_to_layout(signature)
    File.read(signature_to_filename(signature))
  end
  
  def signature_to_filename(signature)
    "#{@layout_path}/#{signature}.#{LAYOUT_EXTENSION}"
  end

end
