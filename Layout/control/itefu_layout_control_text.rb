=begin
  Layoutシステム/書式付文字列を表示するコントロール  
  @note 入力待ちや一文字ずつの表示などがない代わりに、効率よく描画できる（それでも十分重いが…）
=end
class Itefu::Layout::Control::Text < Itefu::Layout::Control::Label
  include Itefu::Layout::Control::Resource
  include Itefu::Layout::Control::FormatString
  attr_bindable :image_source     # [Fixnum] アイコンのID
  attr_bindable :content_alignment  # 行内の縦の整列
  attr_bindable :no_auto_kerning  # [Boolean] 自動カーニングを無効にする

  # アイコンアトラス上の1アイコンのサイズ
  SIZE = Itefu::Rgss3::Definition::Icon::SIZE

  def default_content_alignment; Alignment::BOTTOM; end

  def initialize(parent)
    super
    self.content_alignment = default_content_alignment
    # アイコン画像は固有なので読み込んでおく
    self.image_source = load_image(Itefu::Rgss3::Filename::Graphics::ICONSET)
  end

   # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :image_source, :no_auto_kerning
      true
    else
      super
    end
  end

  # ラベルが無効になるとき、描画情報も無効になるようにする
  def drawing_info_valid?; @text_rect && super; end

  # 描画情報の更新（Label準拠のタイミングで）
  def update_text_rect
    return if drawing_info_valid?
    use_bitmap_applying_font(Itefu::Rgss3::Bitmap.empty, font) do |buffer|
      update_drawing_info(buffer, self.text)
    end
    @text_rect = @drawing_info
  end

  # 描画
  def draw_control(target)
    return unless (text = self.text) && text.empty?.!
    use_bitmap_applying_font(target.buffer, font) do |buffer|
      font_size  = buffer.font.size
      font_color = buffer.font.color.clone

      info = @drawing_info
      cw = content_width
      halign = horizontal_alignment
      valign = vertical_alignment
      calign = content_alignment
      tws = text_word_space
      ics = icon_space
      tls = text_line_space
      dpx = drawing_position_x
      wtf = word_to_fill
      autokerning = 0 unless self.no_auto_kerning
      line_index = 0

      # color
      pwin = target.recent_ancestor(Itefu::Layout::Control::Window)
      # icon
      source = data(image_source)
      dst_rect = Itefu::Rgss3::Rect::TEMPs[0]
      src_rect = Itefu::Rgss3::Rect::TEMPs[1]
      src_rect.width = src_rect.height = SIZE
      # position
      y = drawing_position_y + pos_xy_alignmented(content_height, info.height, valign)
      x = dpx + pos_xy_alignmented(cw, info.line_widths[line_index], halign)

      # process commands
      info.commands.each do |command|
        case command
        when Fixnum
          # 制御文字
          case command_id(command)
          when FixnumedCommand::COLOR
            # 色を変える
            index = command_index(command)
            if index >= 0
              buffer.font.color = pwin.window.text_color(index) if pwin 
            else
              buffer.font.color = font_color
            end
          when FixnumedCommand::ICON
            # アイコンを描画する
            index = command_index(command)
            if source && index >= 0
              lh = info.line_heights[line_index]
              dst_rect.set(x, y + pos_xy_alignmented(lh, buffer.font.size, calign), buffer.font.size, buffer.font.size)
              src_rect.x = Itefu::Rgss3::Definition::Icon.image_x(index)
              src_rect.y = Itefu::Rgss3::Definition::Icon.image_y(index)
              buffer.stretch_blt(dst_rect, source, src_rect)
            end
            x += buffer.font.size + (autokerning||0) + ics
          when FixnumedCommand::TO_BIGGER
            # フォントを大きく
            index = command_index(command)
            buffer.font.size += (index < 0) ? FONT_SIZE_SCALE : index
          when FixnumedCommand::TO_SMALLER
            # フォントを小さく
            index = command_index(command)
            buffer.font.size -= (index < 0) ? FONT_SIZE_SCALE : index
          end
        when CustomCommand::NEW_LINE
          # 改行
          y += info.line_heights[line_index] + tls
          line_index += 1
          x = dpx + pos_xy_alignmented(cw, info.line_widths[line_index], halign)
          autokerning = 0 if autokerning
          if halign == Alignment::STRETCH
            command = CustomCommand::LINE_WRAP
            redo
          end
        when CustomCommand::LINE_WRAP
          # 次の行は自動折り返しされている
          next if autokerning.nil? || autokerning != 0
          word = info.line_words[line_index]
          if word >= 2
            space = cw - info.line_widths[line_index]
            if halign == Alignment::STRETCH || equal_space?(cw, space, word, wtf)
              # 行末がそろうように字間を調整する
              autokerning = space.to_f /  (word - 1)
              x = dpx
            end
          end
        else
          # 文字列
          chara_index = 0
          lh = info.line_heights[line_index]
          while WORD_PATTERN.match(command, chara_index)
            rect = buffer.rich_text_size($&)
            buffer.draw_text(x, y + pos_xy_alignmented(lh, rect.height, calign), rect.width, rect.height, $&)
            # buffer.draw_text(x, y, rect.width, rect.height, $&)
            x += rect.width + (autokerning||0) + tws
            chara_index += $&.size
          end
        end
      end # of each info.commands
      
      # 描画処理で変更されたものを元に戻す
      buffer.font.color = font_color
      buffer.font.size  = font_size
    end
  end

end
