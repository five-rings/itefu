=begin
  Tilemap描画の共通クラス
  @note Itefuから切り離して使用できるよう、Itefu::Rgss3::Resourceは使用しない.
=end
class Itefu::Tilemap::Base
  include Itefu::Tilemap::Definition

  module Exception
    def self.notSupported; Itefu::Exception::NotSupported; end
    def self.notImplemented; Itefu::Exception::NotImplemented; end
  end

  attr_reader :bitmaps
  attr_accessor :map_data
  attr_accessor :flags
  attr_accessor :viewport
  attr_accessor :visible
  attr_accessor :ox
  attr_accessor :oy
  attr_accessor :cell_width
  attr_accessor :cell_height
  
  # 派生クラスごとに実装するべき更新処理
  def update; raise Exception.notImplemented; end

  # 派生クラスごとに実装するべき実際の解放処理
  def dispose_impl; raise Exception.notImplemented; end


  def initialize(viewport)
    @shadow_bitmap = Bitmap.new(32, 32)

    # 描画先の指定に使用する矩形
    # タイル描画のループ内での処理を減らすためにサイズごとにバッファを用意する
    @rect = Rect.new(0, 0, 32, 32)        # 通常のタイル用
    @half_rect = Rect.new(0, 0, 16, 16)   # 分割描画が必要なタイル用

    # タイルごとの描画位置
    # 描画ループ前にサイズを設定し、ループ内でタイルごとに描画位置を指定する
    @dest_rect = Rect.new(0, 0, 0, 0)
    
    # オートタイルなど分割描画するタイル用
    # 描画ループ前にサイズを設定する
    @half_dest_rect = Rect.new(0, 0, 0, 0)

    # 影用
    # 描画ループ前にサイズを設定する
    @shadow_half_rect = Rect.new(0, 0, 0, 0)  # 1/4影
    @shadow_ver_rect = Rect.new(0, 0, 0, 0)   # 縦方向に長い影
    @shadow_hor_rect = Rect.new(0, 0, 0, 0)   # 横方向に長い影

    self.map_data = nil
    self.flags = nil
    self.viewport = viewport
    self.visible = true
    self.ox = 0
    self.oy = 0
    self.cell_width = self.cell_height = DEFAULT_CELL_SIZE
    @bitmaps = []

    self.shadow_color = DEFAULT_SHADOW_COLOR
    @disposed = false
  end

  def dispose
    unless disposed?
      @disposed = true
      if @shadow_bitmap
        @shadow_bitmap.dispose
        @shadow_bitmap = false
      end
      dispose_impl
    end
  end
  
  def disposed?
    @disposed
  end

  def flash_data; raise Exception.notSupported; end
  def flash_data=; raise Exception.notSupported; end

  def shadow_color=(color)
    if color.alpha > 0
      @shadow_bitmap.fill_rect(@shadow_bitmap.rect, color)
    else
      @shadow_bitmap.clear
    end
  end

  # @return [Fixnum] 表示されるタイルマップの幅
  def screen_width
    @viewport && @viewport.rect.width || Graphics.width
  end

  # @return [Fixnum] 表示されるタイルマップの高さ
  def screen_height
    @viewport && @viewport.rect.height || Graphics.height
  end

private

  # オートタイルのidとアトラス上の座標の対応表
  AUTO_TILE_INDICES = [
    [[2, 4], [1, 4], [2, 3], [1, 3]], [[2, 0], [2, 3], [1, 4], [2, 4]], [[1, 3], [3, 0], [1, 4], [2, 4]], [[2, 0], [3, 0], [1, 4], [2, 4]],
    [[1, 3], [2, 3], [1, 4], [3, 1]], [[2, 0], [2, 3], [1, 4], [3, 1]], [[1, 3], [3, 0], [1, 4], [3, 1]], [[2, 0], [3, 0], [1, 4], [3, 1]],
    [[1, 3], [2, 3], [2, 1], [2, 4]], [[2, 0], [2, 3], [2, 1], [2, 4]], [[1, 3], [3, 0], [2, 1], [2, 4]], [[2, 0], [3, 0], [2, 1], [2, 4]],
    [[1, 3], [2, 3], [2, 1], [3, 1]], [[2, 0], [2, 3], [2, 1], [3, 1]], [[1, 3], [3, 0], [2, 1], [3, 1]], [[2, 0], [3, 0], [2, 1], [3, 1]],
    [[0, 4], [1, 4], [0, 3], [1, 3]], [[0, 4], [3, 0], [0, 3], [1, 3]], [[0, 4], [1, 4], [0, 3], [3, 1]], [[0, 3], [3, 0], [0, 4], [3, 1]],
    [[2, 2], [1, 2], [2, 3], [1, 3]], [[2, 2], [1, 2], [2, 3], [3, 1]], [[2, 2], [1, 2], [2, 1], [1, 3]], [[2, 2], [1, 2], [2, 1], [3, 1]],
    [[2, 4], [3, 4], [2, 3], [3, 3]], [[2, 4], [3, 4], [2, 1], [3, 3]], [[2, 0], [3, 4], [2, 3], [3, 3]], [[2, 0], [3, 4], [2, 1], [3, 3]],
    [[2, 4], [1, 4], [2, 5], [1, 5]], [[2, 0], [1, 4], [2, 5], [1, 5]], [[2, 4], [3, 0], [2, 5], [1, 5]], [[2, 0], [3, 0], [1, 5], [2, 5]],
    [[0, 4], [3, 4], [0, 3], [3, 3]], [[2, 2], [1, 2], [2, 5], [1, 5]], [[0, 2], [1, 2], [0, 3], [1, 3]], [[0, 2], [1, 2], [0, 3], [3, 1]],
    [[2, 2], [3, 2], [2, 3], [3, 3]], [[2, 2], [3, 2], [2, 1], [3, 3]], [[2, 4], [3, 4], [2, 5], [3, 5]], [[2, 0], [3, 4], [2, 5], [3, 5]],
    [[0, 4], [1, 4], [0, 5], [1, 5]], [[0, 4], [3, 0], [0, 5], [1, 5]], [[0, 2], [3, 2], [0, 3], [3, 3]], [[0, 2], [1, 2], [0, 5], [1, 5]],
    [[0, 4], [3, 4], [0, 5], [3, 5]], [[2, 2], [3, 2], [2, 5], [3, 5]], [[0, 2], [3, 2], [0, 5], [3, 5]], [[0, 0], [1, 0], [0, 1], [1, 1]],
  ].map {|table| table.map{|data| data.map {|d| d * 16} } }

  # 滝タイルのidとアトラス上の座標の対応表
  WATERFALL_INDICES = [
    [[0, 0], [1, 0], [0, 1], [1, 1]],
    [[2, 0], [3, 0], [2, 1], [3, 1]],
    [[1, 0], [2, 0], [1, 1], [2, 1]],
    [[0, 0], [3, 0], [0, 1], [3, 1]],
  ].map {|table| table.map{|data| data.map {|d| d * 16} } }

  # オートタイルの集合パターンのみのタイルのidとアトラス上の座標の対応表
  AUTO_TILE_C_INDICES = [
    [[2, 2], [1, 2], [2, 1], [1, 1]], [[0, 2], [1, 2], [0, 1], [1, 1]], [[2, 0], [1, 0], [2, 1], [1, 1]], [[0, 0], [1, 0], [0, 1], [1, 1]],
    [[2, 2], [3, 2], [2, 1], [3, 1]], [[0, 2], [3, 2], [0, 1], [3, 1]], [[2, 0], [3, 0], [2, 1], [3, 1]], [[0, 0], [3, 0], [0, 1], [3, 1]],
    [[2, 2], [1, 2], [2, 3], [1, 3]], [[0, 2], [1, 2], [0, 3], [1, 3]], [[2, 0], [1, 0], [2, 3], [1, 3]], [[0, 0], [1, 0], [0, 3], [1, 3]],
    [[2, 2], [3, 2], [2, 3], [3, 3]], [[2, 2], [3, 2], [2, 1], [3, 1]], [[2, 0], [3, 0], [2, 3], [3, 3]], [[0, 0], [3, 0], [0, 3], [3, 3]],
  ].map {|table| table.map{|data| data.map {|d| d * 16} } }

  # タイルの陰情報
# SHADOW_BITS = 4.times.map {|i| 1 << i }

  # 影処理を行う関数のテーブル
  SHADOW_METHOD_TABLE = (0b0000..0b1111).map {|i|
    ("draw_shadow_%04b" % i).intern
  }

  # 矩形サイズを更新する
  def update_rect_buffer
    @dest_rect.width = @shadow_hor_rect.width = @cell_width
    @dest_rect.height = @shadow_ver_rect.height = @cell_height
    @half_dest_rect.width = @shadow_half_rect.width = @shadow_ver_rect.width = @cell_width / 2
    @half_dest_rect.height = @shadow_half_rect.height = @shadow_hor_rect.height =  @cell_height / 2
  end

  # タイルを描画する
  # @param [Bitmap] buffer 描画対象
  # @param [Rect] 描画する範囲を示す矩形
  # @param [Fixnum] id RGSS3のタイルID
  # @param [Fixnum] frame アニメーションのフレーム番号[0-3]
  def draw_tile(buffer, dest_rect, id, frame)
    # このメソッド内にあるコメントアウトされた式は、速度を計測した結果、使われているものより遅かった計算方法や分岐パターン
    # memo: divmodは個別に /,%するより遅い
    #       bit演算は乗除余演算より遅い
    #       複雑な演算で分岐をなくすよりシンプルに分岐したほうが速いことが多い
    #       特にbit演算は分岐をなくせたとしても遅くなることが多い
    if id == 0
      # 空の画像を描画することになるので何もせず処理負荷を減らす
      return

    elsif id < 0x400  # B-E
      part_id = id % 0x80
#     (id & 0x80) == 0 ? ...
#     @rect.x = (id % 8 + (id / 0x80 % 2 * 8)) * 32
      @rect.x = (id % 0x100 < 0x80) ? part_id % 8 * 32 : part_id % 8 * 32 + 256
      @rect.y = part_id / 8 * 32
      buffer.stretch_blt(dest_rect, @bitmaps[5 + id / 0x100], @rect)
      
    elsif id < 0x680  # A5
      part_id = id - 0x600
      @rect.x = part_id % 8 * 32
      @rect.y = part_id / 8 * 32
      buffer.stretch_blt(dest_rect, @bitmaps[4], @rect)

    elsif id < 0xB00  # A1
      part_id = id - 0x800
      tile_index = part_id / 48
      if tile_index < 4
        # Block A, B, C
#       tx = (frame * (1-tile_index/2) + 3 * (tile_index/2)) * 64
        tx = (tile_index < 2) ? frame * 64 : 192
        ty = tile_index % 2 * 96
        draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[0], AUTO_TILE_INDICES[part_id % 48])
      elsif (tile_index % 2) == 0
        # Block D
        # 順に tile_index /= 2 していくのは遅い
#       tx = ((tile_index & 0b0100) >> 2) * 256 + frame * 64
        tx = (tile_index / 4 % 2) * 256 + frame * 64
#       ty = ((tile_index & 0b1000) >> 3) * 192 + ((tile_index & 0b0010) >> 1) * 96
        ty = (tile_index / 8 % 2) * 192 + (tile_index / 2 % 2) * 96
        draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[0], AUTO_TILE_INDICES[part_id % 48])
      else
        # Bock E
#       tx = ((tile_index & 0b0100) >> 2) * 256 + 192
        tx = (tile_index / 4 % 2) * 256 + 192
#       ty = ((tile_index & 0b1000) >> 3) * 192 + ((tile_index & 0b0010) >> 1) * 96 + frame * 32
        ty = (tile_index / 8 % 2) * 192 + (tile_index / 2 % 2) * 96 + frame * 32
        draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[0], WATERFALL_INDICES[part_id % 48])
      end

    elsif id < 0x1100 # A2
      part_id = id - 0xB00
      tile_index = part_id / 48
      tx = tile_index % 8 * 64
      ty = tile_index / 8 * 96
      draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[1], AUTO_TILE_INDICES[part_id % 48])

    elsif id < 0x1700 # A3
      part_id = id - 0x1100
      tile_index = part_id / 48
      tx = tile_index % 8 * 64
      ty = tile_index / 8 * 64
      draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[2], AUTO_TILE_C_INDICES[part_id % 48])

    else              # A4
      part_id = id - 0x1700
      tile_index = part_id / 48
      tx = tile_index % 8 * 64
      if (tile_index % 16) < 8
        ty = tile_index / 16 * 160
        draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[3], AUTO_TILE_INDICES[part_id % 48])
      else
        ty = tile_index / 16 * 160 + 96
        draw_composite_tile(buffer, dest_rect, tx, ty, @bitmaps[3], AUTO_TILE_C_INDICES[part_id % 48])
      end
 
    end
  end
  
  # オートタイルなどタイルパターンの一部を組み合わせるタイルを描画する
  # @param [Bitmap] buffer 描画対象
  # @param [Rect] 描画する範囲を示す矩形
  # @param [Fixnum] tx 描画したいタイルのテクスチャ座標
  # @param [Fixnum] ty 描画したいタイルのテクスチャ座標
  # @param [Bitmpa] source テクスチャアトラス
  # @param [Array<Array<Fixnum>>] table 四隅ごとの、描画したい部分のtx, tyからの相対座標が格納されたテーブル
  def draw_composite_tile(buffer, dest_rect, tx, ty, source, table)
    dest_x = dest_rect.x
    dest_y = dest_rect.y
=begin
    half_width = @half_dest_rect.width
    half_height = @half_dest_rect.height
    table.each.with_index do |data, i|
      @half_rect.x = tx + data[0]
      @half_rect.y = ty + data[1]
      @half_dest_rect.x = dest_x + i % 2 * half_width
      @half_dest_rect.y = dest_y + i / 2 * half_height
      buffer.stretch_blt(@half_dest_rect, source, @half_rect)
    end
=end
    # @hack 以下に loop unrolling する
    # @half_dest_rectのサイズ取得と代入回数を減らすため 0>1>3>2と処理する

    data = table[0]
    @half_rect.x = tx + data[0]
    @half_rect.y = ty + data[1]
    @half_dest_rect.x = dest_x
    @half_dest_rect.y = dest_y
    buffer.stretch_blt(@half_dest_rect, source, @half_rect)
    
    data = table[1]
    @half_rect.x = tx + data[0]
    @half_rect.y = ty + data[1]
    @half_dest_rect.x = dest_x + @half_dest_rect.width
#   @half_dest_rect.y = dest_y
    buffer.stretch_blt(@half_dest_rect, source, @half_rect)
    
    data = table[3]
    @half_rect.x = tx + data[0]
    @half_rect.y = ty + data[1]
#   @half_dest_rect.x = dest_x + @half_dest_rect.width
    @half_dest_rect.y = dest_y + @half_dest_rect.height
    buffer.stretch_blt(@half_dest_rect, source, @half_rect)

    data = table[2]
    @half_rect.x = tx + data[0]
    @half_rect.y = ty + data[1]
    @half_dest_rect.x = dest_x
#   @half_dest_rect.y = dest_y + @half_dest_rect.height
    buffer.stretch_blt(@half_dest_rect, source, @half_rect)
  end
  
=begin
  # 影を描画する
  # @param [Bitmap] buffer 描画対象
  # @param [Rect] 描画する範囲を示す矩形
  # @pmaram [Fixnum] RGSS3の影フラグ
  def draw_shadow(buffer, dest_rect, flag)
    return unless flag
    dest_x = dest_rect.x
    dest_y = dest_rect.y
    half_width = @half_dest_rect.width
    half_height = @half_dest_rect.height
    @half_rect.x = 0
    @half_rect.y = 0
    
    SHADOW_BITS.each.with_index do |bit, i|
      next if (flag & bit) == 0
      @half_dest_rect.x = dest_x + i % 2 * half_width
      @half_dest_rect.y = dest_y + i / 2 * half_height
      buffer.stretch_blt(@half_dest_rect, @shadow_bitmap, @half_rect)
    end
  end
=end
  # @hack 以下 table jump で実装する
  
  # 影なし
  # 分岐を減らすために空のメソッドを呼ぶようにする
  def draw_shadow_0000(buffer, dest_rect)
  end

  # 影 - 左上
  def draw_shadow_0001(buffer, dest_rect)
    buffer.blt(dest_rect.x, dest_rect.y, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 右上
  def draw_shadow_0010(buffer, dest_rect)
    buffer.blt(dest_rect.x + @shadow_half_rect.width, dest_rect.y, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 上辺
  def draw_shadow_0011(buffer, dest_rect)
    @shadow_hor_rect.x = dest_rect.x
    @shadow_hor_rect.y = dest_rect.y
    buffer.stretch_blt(@shadow_hor_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 左下
  def draw_shadow_0100(buffer, dest_rect)
    buffer.blt(dest_rect.x, dest_rect.y + @shadow_half_rect.height, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 左辺
  def draw_shadow_0101(buffer, dest_rect)
    @shadow_ver_rect.x = dest_rect.x
    @shadow_ver_rect.y = dest_rect.y
    buffer.stretch_blt(@shadow_ver_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 左下+右上
  def draw_shadow_0110(buffer, dest_rect)
    buffer.blt(dest_rect.x, dest_rect.y + @shadow_half_rect.height, @shadow_bitmap, @shadow_bitmap.rect)
    buffer.blt(dest_rect.x + @shadow_half_rect.width, dest_rect.y, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 上辺+左下
  def draw_shadow_0111(buffer, dest_rect)
    @shadow_hor_rect.x = dest_rect.x
    @shadow_hor_rect.y = dest_rect.y
    buffer.stretch_blt(@shadow_hor_rect, @shadow_bitmap, @shadow_bitmap.rect)
    buffer.blt(dest_rect.x, dest_rect.y + @shadow_half_rect.height, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 右下
  def draw_shadow_1000(buffer, dest_rect)
    buffer.blt(dest_rect.x + @shadow_half_rect.width, dest_rect.y + @shadow_half_rect.height, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 左上+右下
  def draw_shadow_1001(buffer, dest_rect)
    buffer.blt(dest_rect.x, dest_rect.y, @shadow_bitmap, @shadow_bitmap.rect)
    buffer.blt(dest_rect.x + @shadow_half_rect.width, dest_rect.y + @shadow_half_rect.height, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 右辺
  def draw_shadow_1010(buffer, dest_rect)
    @shadow_ver_rect.x = dest_rect.x + @shadow_ver_rect.width
    @shadow_ver_rect.y = dest_rect.y
    buffer.stretch_blt(@shadow_ver_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 上辺+右下
  def draw_shadow_1011(buffer, dest_rect)
    @shadow_hor_rect.x = dest_rect.x
    @shadow_hor_rect.y = dest_rect.y
    buffer.stretch_blt(@shadow_hor_rect, @shadow_bitmap, @shadow_bitmap.rect)
    buffer.blt(dest_rect.x + @shadow_half_rect.width, dest_rect.y + @shadow_half_rect.height, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 下辺
  def draw_shadow_1100(buffer, dest_rect)
    @shadow_hor_rect.x = dest_rect.x
    @shadow_hor_rect.y = dest_rect.y + @shadow_hor_rect.height
    buffer.stretch_blt(@shadow_hor_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 左上+下辺
  def draw_shadow_1101(buffer, dest_rect)
    buffer.blt(dest_rect.x, dest_rect.y, @shadow_bitmap, @shadow_bitmap.rect)
    @shadow_hor_rect.x = dest_rect.x
    @shadow_hor_rect.y = dest_rect.y + @shadow_hor_rect.height
    buffer.stretch_blt(@shadow_hor_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end
  
  # 影 - 右上+下辺
  def draw_shadow_1110(buffer, dest_rect)
    buffer.blt(dest_rect.x + @shadow_half_rect.width, dest_rect.y, @shadow_bitmap, @shadow_bitmap.rect)
    @shadow_hor_rect.x = dest_rect.x
    @shadow_hor_rect.y = dest_rect.y + @shadow_hor_rect.height
    buffer.stretch_blt(@shadow_hor_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end

  # 影 - 全面
  def draw_shadow_1111(buffer, dest_rect)
    buffer.stretch_blt(dest_rect, @shadow_bitmap, @shadow_bitmap.rect)
  end

end
