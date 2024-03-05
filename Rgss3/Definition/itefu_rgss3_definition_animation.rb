=begin
  RPG::Animation関連の定数定義
=end
module Itefu::Rgss3::Definition::Animation

  module System
    FRAME_RATE  = 4       # ゲーム中の何フレームでアニメーションのフレームを1進めるか
    CELL_MAX    = 8       # 1フレーム内に配置できるセルの最大数
    CELL_SIZE   = 192     # セルに表示する画像のサイズ
  end

  # 位置の基準
  module Position
    TOP     = 0   # 対象の上辺からの相対位置
    CENTER  = 1   # 対象の中心からの相対位置
    BOTTOM  = 2   # 対象の下辺からの相対位置
    SCREEN  = 3   # スクリーン座標

    # @return [Boolean] スクリーンを対象としたアニメーションか
    def self.screen?(position)
      position == SCREEN
    end

    # @return [Boolean] 特定の対象を指定するアニメーションか
    def self.target?(position)
      position != SCREEN
    end
  end
  
  # フラッシュ対象
  module FlashScope
    NONE          = 0   # なし
    TARGET        = 1   # 対象
    SCREEN        = 2   # 画面
    ERASE_TARGET  = 3   # 対象を一時消去

    # @return [Boolean] スクリーンを対象としたアニメーションか
    def self.screen?(position)
      position == SCREEN
    end

    # @return [Boolean] 特定の対象を指定するアニメーションか
    def self.target?(position)
      position == TARGET || position == ERASE_TARGET
    end
  end

  # cell_dataの意味
  module CellData
    # @return [Fixnum] 画像のうちどこを使用するか
    # @note 具体的な値はPatternモジュール以下のメソッドで切り出す
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.pattern(cell_data, index); cell_data[index, 0]; end

    # @return [Fixnum] 表示位置（横）
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.x(cell_data, index); cell_data[index, 1]; end

    # @return [Fixnum] 表示位置（縦）
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.y(cell_data, index); cell_data[index, 2]; end

    # @return [Float] 倍率 , 1.0で等倍
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.zoom(cell_data, index); cell_data[index, 3] / 100.0; end

    # @return [Fixnum] 回転, [0-360]
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.rotation(cell_data, index); cell_data[index, 4]; end

    # @return [Boolean] 左右反転するか
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.mirrored?(cell_data, index); cell_data[index, 5] == 1; end

    # @return [Fixnum] 不透明度, [0-0xff]
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.opacity(cell_data, index); cell_data[index, 6]; end

    # @return [Fixnum] ブレンド方法(Itefu::Rgss3::Sprite::BlendingType)
    # @param [Table] cell_data セルデータ
    # @param [Fixnum] index セル番号
    def self.blend_type(cell_data, index); cell_data[index, 7]; end
  end
  
  # パターンの判定
  module Pattern
    # @return [Boolean] 有効な値か
    # @param [Fixnum] CellData.patternで取り出した値
    def self.valid?(pattern); pattern && pattern >= 0; end

    # @return [Boolean] Bitmap1を使用するか
    # @note falseならBitmap2を使用する
    # @param [Fixnum] CellData.patternで取り出した値
    def self.uses_bitmap1?(pattern); pattern < 100; end

    # @return [Boolean] 使用する画像内の位置(縦)
    # @param [Fixnum] CellData.patternで取り出した値
    def self.to_x(pattern); pattern % 5; end

    # @return [Boolean] 使用する画像内の位置(横)
    # @param [Fixnum] CellData.patternで取り出した値
    def self.to_y(pattern); pattern % 100 / 5; end
  end

end

