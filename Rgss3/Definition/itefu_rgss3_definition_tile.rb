=begin
  RGSS3やそのデフォルト実装で使用しているタイル関連の定数
=end
module Itefu::Rgss3::Definition::Tile
  SIZE = 32
  WIDTH = SIZE
  HEIGHT = SIZE
  PATTERN_MAX = 4

  # @return [String] ファイル名を返す
  # @param [String] name キャラチップの名前
  def self.filename(name)
    Itefu::Rgss3::Filename::Graphics::CHARACTERS_s % name
  end
  
  # @return [Boolean] 有効なタイルIDか
  def self.valid_id?(tile_id)
    tile_id && tile_id != 0
  end
  
  # タイルのフラグ
  module Flags
    module Type
      PROHIBIT_TO_MOVE_DOWN   = 0x0001    # 下方向通行不可
      PROHIBIT_TO_MOVE_LEFT   = 0x0002    # 左方向通行不可
      PROHIBIT_TO_MOVE_RIGHT  = 0x0004    # 右方向通行不可
      PROHIBIT_TO_MOVE_UP     = 0x0008    # 上方向通行不可
      OVERLAY                 = 0x0010    # オーバーレイ
      LADDER                  = 0x0020    # はしご
      BUSH                    = 0x0040    # しげみ
      COUNTER                 = 0x0080    # カウンター(台)
      DAMAGE_FLOOR            = 0x0100    # ダメージを受ける床
      PROHIBIT_BOAT           = 0x0200    # 小舟への乗船不可
      PROHIBIT_SHIP           = 0x0400    # 船への乗船不可
      PROHIBIT_PLANE          = 0x0800    # 飛空艇への乗船不可
      TAG                     = 0xf000    # 地形タグ
    end
    include Type
    
    # @return [Fixnum] 地形タグ[0-7]を取得
    # @param [Fixnum] flag タイルのフラグを指定する
    def self.terrain_tag(flag)
      (flag & Type::TAG) >> 12
    end
    
    # @return [Tile::Flags] 指定した方向についての通行禁止フラグ
    # @param [Direction] 通行禁止フラグを立てたい方向
    def self.directional_prohibition(direction)
      case direction
      when Itefu::Rgss3::Definition::Direction::DOWN
        PROHIBIT_TO_MOVE_DOWN
      when Itefu::Rgss3::Definition::Direction::LEFT
        PROHIBIT_TO_MOVE_LEFT
      when Itefu::Rgss3::Definition::Direction::RIGHT
        PROHIBIT_TO_MOVE_RIGHT
      when Itefu::Rgss3::Definition::Direction::UP
        PROHIBIT_TO_MOVE_UP
      else
        PROHIBIT_TO_MOVE_DOWN | PROHIBIT_TO_MOVE_LEFT | PROHIBIT_TO_MOVE_RIGHT | PROHIBIT_TO_MOVE_UP 
      end
    end
  end
  
  # @return [Fixnum] タイルパターン
  # @param [Fixnum] n カウンター [0-3]
  def self.pattern(n)
    n < 3 ? n : 1
  end
  
  # @return [Fixnum, Fixnum] 使用する画像にタイルが何×何で並んでいるか
  def self.image_grids(atlasname)
    sign = atlasname[/^[\!\$]./]
    if sign && sign.include?('$')
      return 3, 4
    else
      return 12, 8
    end
  end
  
  # @return [Fixnum] 指定したパターンのタイルが画像のどこのx座標に置かれているか
  # @param [Fixnum] index タイルのインデックス
  # @param [Fixnum] pattern タイルアニメーションのパターン
  # @param [Fixnum] cw 1タイルの幅
  def self.image_x(index, pattern, cw)
    (index % 4 * 3 + pattern) * cw
  end
  
  # @return [Fixnum] 指定した向きのタイルが画像のどこのy座標に置かれているか
  # @param [Fixnum] index タイルのインデックス
  # @param [Itefu::Rgss3::Definition::Direction] direction タイルの向き
  # @param [Fixnum] ch 1タイルの高さ
  def self.image_y(index, direction, ch)
    (index / 4 * 4 + (direction - 2) / 2) * ch  # Rgss3オリジナル実装の定義に拠る
  end

  # @return [Fixnum] イベント内のタイルidをマップ内のタイルセットindexに変換する
  # @param [Fixnum] tile_id イベント内のタイルid
  def self.tileset_index(tile_id)
    5 + tile_id / 256  # Rgss3オリジナル実装の定義に拠る
  end
  
  # @return [Fixnum] イベント内のタイルidをタイルのアトラス画像上のx座標に変換する
  # @param [Fixnum] tile_id イベント内のタイルid
  def self.tile_x(tile_id)
    (tile_id / 128 % 2 * 8 + tile_id % 8) * 32  # Rgss3オリジナル実装の定義に拠る
  end
  
  # @return [Fixnum] イベント内のタイルidをタイルのアトラス画像上のy座標に変換する
  # @param [Fixnum] tile_id イベント内のタイルid
  def self.tile_y(tile_id)
    tile_id % 256 / 8 % 16 * 32  # Rgss3オリジナル実装の定義に拠る
  end

end
