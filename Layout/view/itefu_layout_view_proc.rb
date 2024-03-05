=begin
  Layoutシステム/Procからレイアウトを生成する
=end
module Itefu::Layout::View::Proc
  include Itefu::Layout::View

  def load_layout(context = nil, &block)
    ITEFU_DEBUG_ASSERT(block, "View::Proc needs block to layout.")
    super(block, context)
  end

  def signature_to_layout(signature)
    signature
  end
  
end
