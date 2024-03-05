=begin
  Layoutシステム/キャラチップを表示するコントロール
=end
class Itefu::Layout::Control::Chara < Itefu::Layout::Control::Bitmap
  attr_bindable :chara_index        # [Fixnum] アトラス上のキャラindex
  attr_bindable :chara_direction    # [Direction::Orthogonal] 方向
  attr_bindable :chara_pattern      # [Fixnum] アニメーションパターン
  attr_bindable :chara_anime_frame  # [Fixnum] キャラアニメを更新するフレーム数, 0で再生しない

  # 一般的なキャラチップサイズ ($から始まるファイルでは異なる)
  SIZE = Itefu::Rgss3::Definition::Tile::SIZE

  def load_image(name, *args)
    super(Itefu::Rgss3::Definition::Tile.filename(name), *args)
  end

  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :image_source
      # テクスチャが変わるとキャラチップサイズも変わる可能性があるので再計算する
      if (id = image_source) && (fn = filename(id)) && (source = data(id))
        row, col = Itefu::Rgss3::Definition::Tile.image_grids(File.basename(fn))
        @cw = source.width  / row
        @ch = source.height / col
      else
        @cw = @ch = nil
      end
    when :chara_anime_frame
      @pattern_counter ||= 0
    end
    super
  end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :image_source
      # AUTOでなければサイズは変わらない
      (width != Size::AUTO) && (height != Size::AUTO)
    when :chara_index, :chara_pattern, :chara_direction
      # どのキャラチップを選んでも選んでもサイズには影響しない
      true
    else
      super
    end
  end
  
  # 計測
  def impl_measure(available_width, available_height)
    # オートサイズの場合はドットバイドットになるサイズにする
    @desired_width  = (@cw || SIZE) + padding.width  if width  == Size::AUTO
    @desired_height = (@ch || SIZE) + padding.height if height == Size::AUTO
  end
  
  def inner_width
    case horizontal_alignment
    when Alignment::STRETCH
      super
    else
      @cw || SIZE
    end
  end
  
  def inner_height
    case vertical_alignment
    when Alignment::STRETCH
      super
    else
      @ch || SIZE
    end
  end

  # 更新
  def impl_update
    frame = chara_anime_frame || 0
    if frame > 0
      @pattern_counter += 1
      if @pattern_counter >= frame * Itefu::Rgss3::Definition::Tile::PATTERN_MAX
        @pattern_counter = 0 
      end
      corrupt if @pattern_counter % frame == 0
    end
  end

  # 描画
  def draw_control(target)
    return unless (index = chara_index) && (source = data(image_source)) && @cw && @ch
    frame     = chara_anime_frame || 0
    pattern   = chara_pattern     || 0
    direction = chara_direction   || Direction::DOWN

    if frame > 0
      pattern = (pattern + @pattern_counter / frame) % Itefu::Rgss3::Definition::Tile::PATTERN_MAX
    end
    pattern = Itefu::Rgss3::Definition::Tile.pattern(pattern)

    x = Itefu::Rgss3::Definition::Tile.image_x(index, pattern,   @cw)
    y = Itefu::Rgss3::Definition::Tile.image_y(index, direction, @ch)
    draw_bitmap(target.buffer, source, x, y, @cw, @ch)
  end
  
end
