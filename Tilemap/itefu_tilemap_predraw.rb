=begin
 生成時に巨大なバッファにマップ全体を描画するタイルマップ
  @warning マップサイズ*セルサイズ(縦*横)のバッファを4枚作成するのでメモリを大きく消費する.
           map_data 設定時にバッファを作成する
           cell_width, cell_heightはそれより先に設定しなければならない.
           cell_width/height を後から設定しなおす場合、map_dataを自己代入すればバッファを再生成する
=end
class Itefu::Tilemap::Predraw < Itefu::Tilemap::Base
  attr_reader :planes
  
  def initialize(viewport = nil)
    @planes = {}
    @frame = 0
    @frame_count = 0
    super
  end

  def update
    if (@frame_count += 1) >= 30
      @frame_count = 0
      @frame = (@frame + 1) % 4
    end
    update_plane_visibility(@frame > 2 ? 1 : @frame)
  end
  
  def map_data=(value)
    @map_data = value
    clear_buffer
    if value
      create_buffer
      refresh
    end
  end
  
  def flags=(value)
    @flags = value
    refresh
  end

  def viewport=(value)
    @viewport = value
    @planes.each_value {|plane| plane.viewport = value unless plane.disposed? }
  end
  
  def visible=(value)
    @visible = value
  end
  
  def ox=(value)
    @ox = value
    @planes.each_value {|plane| plane.ox = value }
  end

  def oy=(value)
    @oy = value
    @planes.each_value {|plane| plane.oy = value }
  end
  
private
  # 影がない場合にスキップできるよう  0 を nil にしておく
  SHADOW_METHOD_TABLE = [nil] + SHADOW_METHOD_TABLE[1, 0b1111]

  def dispose_impl
    clear_buffer
  end

  # 内部で使用しているバッファを解放する
  def clear_buffer
    @planes.each_value {|plane|
      unless plane.disposed?
        plane.bitmap.dispose
        plane.dispose
      end
    }
    @planes.clear
  end

  # 内部で必要とするバッファを作成する
  def create_buffer
    bw = @map_data.xsize * @cell_width
    bh = @map_data.ysize * @cell_height

    3.times {|i|
      @planes[:"ground#{i}"] = Plane.new(viewport).tap {|plane|
        plane.bitmap = Bitmap.new(bw, bh)
        plane.z = Z_UNDER_CHARACTERS
        plane.visible = false
      }
    }
    @planes[:overlay] = Plane.new(viewport).tap {|plane|
      plane.bitmap = Bitmap.new(bw, bh)
      plane.z = Z_OVER_CHARACTERS
      plane.visible = false
    }
  end

  # 表示/非表示を切り替える
  # @param [Fixnum] frame アニメーションのフレーム番号[0-3]
  def update_plane_visibility(frame)
    if @visible
      3.times {|i| @planes[:"ground#{i}"].visible = (frame == i) }
      @planes[:overlay].visible = true
    else
      @planes.each_value {|plane| plane.visible = false }
    end
  end

  # 描画内容を更新する
  def refresh
    return if disposed?
    return unless @map_data && @flags && @bitmaps.empty?.!

    update_rect_buffer

    flag = nil
    cell_width = @cell_width
    cell_height = @cell_height
    map_data = @map_data
    flags = @flags
    dest_rect = @dest_rect
    bitmap_ground0 = @planes[:ground0].bitmap
    bitmap_ground1 = @planes[:ground1].bitmap
    bitmap_ground2 = @planes[:ground2].bitmap
    bitmap_overlay = @planes[:overlay].bitmap

    w = (0...@map_data.xsize)
    h = (0...@map_data.ysize)

    dest_rect.y = 0
    h.each do |y|
      dest_rect.x = 0
      w.each do |x|
        # ground
        flag = map_data[x, y, 0]
        draw_tile(bitmap_ground0, dest_rect, flag, 0)
        draw_tile(bitmap_ground1, dest_rect, flag, 1)
        draw_tile(bitmap_ground2, dest_rect, flag, 2)
        # ground extension
        flag = map_data[x, y, 1]
        draw_tile(bitmap_ground0, dest_rect, flag, 0)
        draw_tile(bitmap_ground1, dest_rect, flag, 0)
        draw_tile(bitmap_ground2, dest_rect, flag, 0)
        # shadow
        if flag = SHADOW_METHOD_TABLE[map_data[x, y, 3]]
          send(flag, bitmap_ground0, dest_rect)
          send(flag, bitmap_ground1, dest_rect)
          send(flag, bitmap_ground2, dest_rect)
        end
        # overlay
        flag = map_data[x, y, 2]
        # (@flags[flag] & 0x10) != 0
        if (flags[flag] / 16 % 2) != 0
          draw_tile(bitmap_overlay, dest_rect, flag, 0)
        else
          draw_tile(bitmap_ground0, dest_rect, flag, 0)
          draw_tile(bitmap_ground1, dest_rect, flag, 0)
          draw_tile(bitmap_ground2, dest_rect, flag, 0)
        end

        dest_rect.x += cell_width
      end
      dest_rect.y += cell_height
    end
  end

end
