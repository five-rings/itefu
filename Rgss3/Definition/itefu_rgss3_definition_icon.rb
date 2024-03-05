=begin
  RGSS3やそのデフォルト実装で使用しているアイコン関連の定数
=end
module Itefu::Rgss3::Definition::Icon
  SIZE = 24   # アトラス画像上の物理アイコンサイズ
  
  # @return [Fixnum] 指定したindexのアイコンが置いてあるアトラス画像上のx座標
  # @param [Fixnum] index アイコンインデックス
  def self.image_x(index)
    index % 16 * SIZE  # Rgss3オリジナル実装の定義に拠る
  end
  
  # @return [Fixnum] 指定したindexのアイコンが置いてあるアトラス画像上のy座標
  # @param [Fixnum] index アイコンインデックス
  def self.image_y(index)
    index / 16 * SIZE  # Rgss3オリジナル実装の定義に拠る
  end

end
