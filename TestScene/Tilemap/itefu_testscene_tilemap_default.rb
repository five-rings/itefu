=begin
  RGSS3デフォルト実装のTilemapを使って描画するテスト
=end
class Itefu::TestScene::Tilemap::Default < Itefu::TestScene::Tilemap::Base
  def tilemap_klass; Itefu::Rgss3::Tilemap; end
end
