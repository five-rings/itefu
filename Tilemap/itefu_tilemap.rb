=begin
  ruby実装のTilemap
=end
module Itefu::Tilemap
  module Definition
    Z_UNDER_CHARACTERS = 0    # RGSS3の定義に拠る
    Z_OVER_CHARACTERS = 200   # RGSS3の定義に拠る
    DEFAULT_CELL_SIZE = 32    # RGSS3の定義に拠る
    DEFAULT_SHADOW_COLOR = Color.new(0, 0, 0, 0x7f)
  end
  include Definition 
end
