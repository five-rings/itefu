=begin
  画面分を描画し、はみ出した分はつど更新するタイルマップ
  @warning 画面と同じサイズのバッファを4枚作成する.
           viewportを設定した場合はバッファサイズもViewportのサイズを同じになる.
           viewportを viewport= で再設定した時点でバッファを生成しなおす.
  @warning タイルのアニメーションの更新にかなりの処理時間がかかるので、falseにして使用することを推奨する
=end
class Itefu::Tilemap::Redraw < Itefu::Tilemap::Base
  attr_reader :sprites
  attr_accessor :animation
  
  def initialize(viewport = nil)
    @animation = true
    @need_to_refresh = true
    @sprites = {}
    @secondary_buffer = {}
    @frame = 0
    @frame_count = 0

    super
    
    # 本来はこのタイミングで処理すべきだがviewpoer=で作成されるので呼ばない
    # viewportがnilでもGraphicsのサイズでバッファは生成される
    # create_buffer
  end
  
  def update
    if @animation
      if (@frame_count += 1) >= 30
        @frame_count = 0
        @frame = (@frame + 1) % 4
        @need_to_refresh = true
      end
    end
    refresh(@frame > 2 ? 1 : @frame)
    @sprites.each_value(&:update)
  end
  
  def map_data=(value)
    @map_data = value
    @ox_drawn = @oy_drawn = nil
    @need_to_refresh = true
  end
  
  def flags=(value)
    @flags = value
    @ox_drawn = @oy_drawn = nil
    @need_to_refresh = true
  end
  
  def cell_width=(value)
    @cell_width = value
    @ox_drawn = @oy_drawn = nil
    @need_to_refresh = true
  end

  def cell_height=(value)
    @cell_height = value
    @ox_drawn = @oy_drawn = nil
    @need_to_refresh = true
  end
  
  def ox=(value)
    value = value.to_i
    if @ox != value
      @ox = value
      @need_to_refresh = true
    end
  end

  def oy=(value)
    value = value.to_i
    if @oy != value
      @oy = value
      @need_to_refresh = true
    end
  end

  def viewport=(value)
    @viewport = value
    @sprites.each_value {|sprite| sprite.viewport = value unless sprite.disposed? }
    clear_buffer
    create_buffer unless disposed?
  end
  
  def visible=(value)
    @visible = value
    @sprites.each_value {|sprite| sprite.visible = value }
  end


private
  def dispose_impl
    self.viewport = nil
    clear_buffer
  end

  # 内部で使用しているバッファを解放する
  def clear_buffer
    @sprites.each_value {|sprite|
      sprite.bitmap.dispose
      sprite.dispose
    } unless disposed?
    @sprites.clear
    @secondary_buffer.each_value {|bitmap|
      bitmap.dispose
    } unless disposed?
    @secondary_buffer.clear
  end

  # 内部で必要とするバッファを作成する
  def create_buffer
    sw = screen_width
    sh = screen_height

    @sprites[:ground] = Sprite.new(viewport).tap {|sprite|
      sprite.bitmap = Bitmap.new(sw, sh)
      sprite.z = Z_UNDER_CHARACTERS
      sprite.visible = @visible
    }
    @sprites[:overlay] = Sprite.new(viewport).tap {|sprite|
      sprite.bitmap = Bitmap.new(sw, sh)
      sprite.z = Z_OVER_CHARACTERS
      sprite.visible = @visible
    }
    @sprites.each_key do |key|
      @secondary_buffer[key] = Bitmap.new(sw, sw)
    end
  end

  # 描画内容を更新する
  # @param [Fixnum] frame アニメーションのフレーム番号[0-3]
  def refresh(frame)
    return if disposed?
    return unless @need_to_refresh && @map_data && @flags
    @need_to_refresh = false

    if @ox_drawn && @oy_drawn
      diff_x = @ox - @ox_drawn
      diff_y = @oy - @oy_drawn
      if (diff_x != 0 || diff_y != 0) && diff_x.abs < screen_width && diff_y.abs < screen_height
        part_refresh(frame, diff_x, diff_y)
      else
        full_refresh(frame)
      end
    else
      full_refresh(frame)
    end
    @ox_drawn = @ox
    @oy_drawn = @oy
  end

  # 更新部分のみ再描画する  
  # @param [Fixnum] frame アニメーションのフレーム番号[0-3]
  # @param [Fixnum] diff_x 横方向の変化量
  # @param [Fixnum] diff_y 縦方向の変化量
  def part_refresh(frame, diff_x, diff_y)
    sw = screen_width
    sh = screen_height

    if diff_x < 0
      start_x = @ox
      width = -diff_x
    else
      start_x = @ox + sw - diff_x
      width = diff_x
    end
    
    if diff_y < 0
      start_y = @oy
      height = -diff_y
    else
      start_y = @oy + sh - diff_y
      height = diff_y
    end

    @dest_rect.set(
      # 左,上: 移動前の左上の属するタイルの隣のタイルからを切り取る
      # 右,下: 移動後に見切れる位置から切り取る
      diff_x < 0 ? (@cell_width - (@ox + width) % @cell_width) % @cell_width : width,
      diff_y < 0 ? (@cell_height - (@oy + height) % @cell_height) % @cell_height : height,
      # 左,上: 多めに切り取っても画面外でクリッピングされるので画面サイズ分切り取る
      # 右,下: 左端が属していたタイルは含まずにその手前までを切り取る
      sw - (diff_x > 0 ? (@ox - width) % @cell_width : 0),
      sh - (diff_y > 0 ? (@oy - height) % @cell_height : 0)
    )
    @sprites.each {|key, sprite|
      b = @secondary_buffer[key]
      @secondary_buffer[key] = sprite.bitmap
      b.clear
      b.blt(
        # 左,上: 切り取った部分を移動分だけずらす
        # 右,下: 切り取った部分を画面端から描画する
        diff_x < 0 ? width + (@cell_width - (@ox + width) % @cell_width) % @cell_width : 0,
        diff_y < 0 ? height + (@cell_height - (@oy + height) % @cell_height) % @cell_height : 0,
        sprite.bitmap, @dest_rect)
      sprite.bitmap = b
    }

    refresh_impl(frame, start_x, @oy, width, sh) if width > 0
    refresh_impl(frame, @ox, start_y, sw, height) if height > 0
  end
  
  # 画面全体を再描画する
  # @param [Fixnum] frame アニメーションのフレーム番号[0-3]
  def full_refresh(frame)
    @sprites.each_value {|sprite|
      sprite.bitmap.clear
    }
    refresh_impl(frame, @ox, @oy, screen_width, screen_height)
  end
  
  # タイルを描画する
  # @param [Fixnum] frame アニメーションのフレーム番号[0-3]
  # @param [Fixnum] start_x スクリーンの左上に来るマップの位置 (スクリーン座標)
  # @param [Fixnum] start_y スクリーンの左上に来るマップの位置 (スクリーン座標)
  # @param [Fixnum] width 描画サイズ
  # @param [Fixnum] height　描画サイズ
  # @note 描画サイズがタイルサイズと一致しない場合、指定サイズより大きいタイルサイズの単位で再描画を行う
  def refresh_impl(frame, start_x, start_y, width, height)
    update_rect_buffer

    cell_width = @cell_width
    cell_height = @cell_height
    map_data = @map_data
    flags = @flags
    dest_rect = @dest_rect
    bitmap_ground = @sprites[:ground].bitmap
    bitmap_overlay = @sprites[:overlay].bitmap

    tile_ox, rest_x = @ox.divmod(cell_width)
    tile_oy, rest_y = @oy.divmod(cell_height)
    tile_x = start_x / cell_width
    tile_y = start_y / cell_height
    tile_w = width / cell_width
    tile_h = height / cell_height

    w = (tile_x..(tile_x + tile_w))
    h = (tile_y..(tile_y + tile_h))
    sw = map_data.xsize
    sh = map_data.ysize

    base_x = (tile_x - tile_ox) * cell_width - rest_x
    dest_rect.y = (tile_y - tile_oy) * cell_height - rest_y
    h.each do |y|
      y %= sh
      dest_rect.x = base_x
      w.each do |x|
        x %= sw
        # ground
        draw_tile(bitmap_ground, dest_rect, map_data[x, y, 0], frame)
        # ground extension
        draw_tile(bitmap_ground, dest_rect, map_data[x, y, 1], frame)
        # shadow
        if flag = SHADOW_METHOD_TABLE[map_data[x, y, 3]]
          send(flag, bitmap_ground, dest_rect)
        end
        # overlay
        # (@flags[flag] & 0x10) != 0
        if (flags[map_data[x, y, 2]] / 16 % 2) != 0
          draw_tile(bitmap_overlay, dest_rect, map_data[x, y, 2], frame)
        else
          draw_tile(bitmap_ground, dest_rect, map_data[x, y, 2], frame)
        end

        dest_rect.x += cell_width
      end
      dest_rect.y += cell_height
    end
  end

end
