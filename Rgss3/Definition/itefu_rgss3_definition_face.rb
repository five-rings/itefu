=begin
  RGSS3やそのデフォルト実装で使用している顔グラフィック関連の定数
=end
module Itefu::Rgss3::Definition::Face
  SIZE = 96   # 顔グラフィックのサイズ

  # @return [Fixnum] 指定した顔グラフィックが配置されている画像上の横座標
  # @param [Fixnum] index 何番目の顔グラフィックか
  def self.image_x(index)
    index % 4 * SIZE
  end
  
  # @return [Fixnum] 指定した顔グラフィックが配置されている画像上の縦座標
  # @param [Fixnum] index 何番目の顔グラフィックか
  def self.image_y(index)
    index / 4 * SIZE
  end

  # @return [String] ファイル名を返す
  # @param [String] name 顔グラフィックの名前  
  def self.filename(name)
    Itefu::Rgss3::Filename::Graphics::FACES_s % name
  end

end
