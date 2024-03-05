=begin
  RGSS3やそのデフォルト実装で使用しているフキダシアイコン関連の定数
=end
module Itefu::Rgss3::Definition::Balloon
  SIZE = 32                 # アトラス画像上の物理アイコンサイズ
  ANIMATION_FRAME_SIZE = 8  # コマ数
  
  # @return [Fixnum] 指定したフキダシアイコンの画像があるアトラス画像上のx座標
  # @param [Fixnum] index フキダシアイコンの識別子
  # @param [Fixnum] frame アニメーションのコマ数
  def self.image_x(index, frame)
    frame * SIZE
  end
  
  # @return [Fixnum] 指定したフキダシアイコンの画像があるアトラス画像上のy座標
  # @param [Fixnum] index フキダシアイコンの識別子
  # @param [Fixnum] frame アニメーションのコマ数
  def self.image_y(index, frame)
    index * SIZE
  end

end
