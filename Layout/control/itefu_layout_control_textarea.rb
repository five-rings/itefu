=begin
  Layoutシステム/入力待ちなどに対応した書式付文字表示コントロール
=end
class Itefu::Layout::Control::TextArea < Itefu::Layout::Control::Base
  include Itefu::Layout::Control::Resource
  include Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Control::Drawable
  include Itefu::Layout::Control::Font
  include Itefu::Layout::Control::FormatString
  include Itefu::Layout::Control::Focusable
  attr_bindable :image_source       # [Fixnum] アイコンのID
  attr_bindable :text               # [String] 表示する文章
  attr_bindable :text_anime_frame   # [Fixnum] 文字を表示するフレーム間隔
  attr_bindable :content_alignment  # 行内の縦の整列
  attr_bindable :no_auto_kerning  # [Boolean] 自動カーニングを無効にする
  
  # アイコンアトラス上の1アイコンのサイズ
  SIZE = Itefu::Rgss3::Definition::Icon::SIZE
  # text_anime_frameの初期値
  DEFAULT_TEXT_ANIME_FRAME = 1

  DrawingContext = Struct.new(
    :font,          # [Font] 描画時に適用するフォント
    :skip,          # [Boolean] スキップ中か
    :auto_feed,     # [Boolean] 表示し終わった際に自動的に決定するか
    :inputted,      # [Boolean] 外部から入力があったか
  )
  
  def default_content_alignment; Alignment::BOTTOM; end

  def initialize(parent)
    super
    @fiber = nil
    @drawing_context = DrawingContext.new

    self.content_alignment = default_content_alignment
    # アイコン画像は固有なので読み込んでおく
    self.image_source = load_image(Itefu::Rgss3::Filename::Graphics::ICONSET)
  end
  
  # DrawingContextを初期化する
  def clear_drawing_context
    context = @drawing_context
    context.font      = (font || DEFAULT_FONT).clone
    context.skip      = false
    context.auto_feed = false
    context.inputted  = false
 end
  
  def invalidate_drawing_info
    @fiber = nil
    super
  end
  
  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :text
      invalidate_drawing_info
    end
    super
  end

   # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :text_anime_frame, :image_source, :no_auto_kerning
      true
    when :text
      # サイズが指定されているなら文字がかわっても変更されない
      (width != Size::AUTO) && (height != Size::AUTO)
    else
      super
    end
  end
  
  # 再描画不要の条件
  def stable_in_appearance?(name)
    case name
    when :text_anime_frame
      true
    else
      super
    end
  end

  # 入力処理
  def on_operation_instructed(code, *args)
    case code
    when Operation::DECIDE
      skip_message
    end
  end

  # メッセージ送り
  def skip_message
    if @fiber
      # 表示処理中
      @drawing_context.inputted = true
    else
      # 表示し終わっている
      execute_callback(:message_decided, false)
    end
  end

  # 文字列の描画が完了した際に呼ばれる
  def finished_to_draw_characters(target)
    execute_callback(:message_shown)
    if focused?.! || @drawing_context.auto_feed
      # 自動的に決定する
      execute_callback(:message_decided, true)
    else
      pwin = target.recent_ancestor(Itefu::Layout::Control::Window)
      pwin.window.pause = true if pwin
    end
  end
 
  # 描画情報の更新 
  def update_drawing_info
    return if drawing_info_valid?
    text = self.text
    use_bitmap_applying_font(Itefu::Rgss3::Bitmap.empty, font) do |buffer|
      super(buffer, text)
    end
    execute_callback(:updated_drawing_info, text, @drawing_info)
  end

  # 計測
  def impl_measure(available_width, available_height)
    update_drawing_info
    if drawing_info_valid?
      @desired_width  = padding.width  + @drawing_info.width   if width  == Size::AUTO
      @desired_height = padding.height + @drawing_info.height  if height == Size::AUTO
    end
  end  

  def inner_width
    if drawing_info_valid?
      @drwaing_info.width
    else
      super
    end
  end
  
  def inner_height
    if drawing_info_valid?
      @drawing_info.height
    else
      super
    end
  end
  
  # 描画
  def impl_draw
    # コントロールのサイズが固定でテキストだけが変わったときなどに更新する必要がある
    update_drawing_info
    super
    # 実際の描画処理
    @fiber.resume if @fiber
  end

  # テキスト描画
  # @note ここでは描画したことにしておいて、実際にはFiberを使って遅延描画する
  def draw_control(target)
    pwin = target.recent_ancestor(Itefu::Layout::Control::Window)
    pwin.window.pause = false  if pwin

    @fiber = Fiber.new {
      clear_drawing_context
      process_commands(target, @drawing_info, @drawing_context, text_anime_frame || DEFAULT_TEXT_ANIME_FRAME)
      finished_to_draw_characters(target)
      @fiber = nil
    }
  end

private

  # コマンドを処理する
  def process_commands(target, info, context, frame)
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
    wrapped_line = false

    # icon
    source = data(image_source)
    # position
    y = drawing_position_y + pos_xy_alignmented(content_height, info.height, valign)
    x = dpx + pos_xy_alignmented(cw, info.line_widths[line_index], halign)

    # process commands
    info.commands.each do |command|
      skip = context.skip || context.inputted || frame <= 0

      case command
      when Fixnum
        # 制御文字
        case command_id(command)
        when FixnumedCommand::COLOR
          # 色を変える
          index = command_index(command)
          if index >= 0
            pwin = target.recent_ancestor(Itefu::Layout::Control::Window)
            context.font.color = pwin.window.text_color(index) if pwin 
          else
            context.font.color = (font || DEFAULT_FONT).color
          end
        when FixnumedCommand::ICON
          # アイコンを描画する
          index = command_index(command)
          if source && index >= 0
            # TEMPsは外部でも使用される可能性があるので、毎回再設定する
            dst_rect = Itefu::Rgss3::Rect::TEMPs[0]
            lh = info.line_heights[line_index]
            dst_rect.set(x, y + pos_xy_alignmented(lh, context.font.size, calign), context.font.size, context.font.size)
            src_rect = Itefu::Rgss3::Rect::TEMPs[1]
            src_rect.set(Itefu::Rgss3::Definition::Icon.image_x(index),
                         Itefu::Rgss3::Definition::Icon.image_y(index),
                         SIZE, SIZE)
            use_bitmap_applying_font(target.buffer, context.font) do |buffer|
              buffer.stretch_blt(dst_rect, source, src_rect)
            end
          end
          x += context.font.size + (autokerning||0) + ics
          frame.times {
            break if context.inputted
            Fiber.yield
          } unless skip
        when FixnumedCommand::TO_BIGGER
          # フォントを大きく
          index = command_index(command)
          context.font.size += (index < 0) ? FONT_SIZE_SCALE : index
        when FixnumedCommand::TO_SMALLER
          # フォントを小さく
          index = command_index(command)
          context.font.size -= (index < 0) ? FONT_SIZE_SCALE : index
        when FixnumedCommand::WAIT_FOR_INPUT
          # 入力を待つ
          if focused?
            pwin = target.recent_ancestor(Itefu::Layout::Control::Window)
            pwin.window.pause = true if pwin
            context.inputted = false
            Fiber.yield until context.inputted
            context.inputted = false
            pwin.window.pause = false if pwin
          end
        when FixnumedCommand::AUTO_FEED
          # 自動で次へ進む状態へ設定する
          context.auto_feed = true
        when FixnumedCommand::WAIT_SHORT_TIME
          # 少し待つ
          SHORT_WAIT_FRAME.times {
            break if context.inputted
            Fiber.yield
          } unless skip
        when FixnumedCommand::WAIT_LONG_TIME
          # 長く待つ
          LONG_WAIT_FRAME.times {
            break if context.inputted
            Fiber.yield
          } unless skip
        when FixnumedCommand::SKIP
          # 残りの文字を表示する
          context.skip = true
        when FixnumedCommand::CANCEL_TO_SKIP
          # SKIPを取り消す
          context.skip = false
        when FixnumedCommand::SHOW_BUDGET
          # 所持金ウィンドウを開く
          execute_callback(:commanded_to_show_budget)
        end
      when CustomCommand::NEW_LINE
        # 改行
        if wrapped_line
          wrapped_line = false
          # 自動改行の改行では \> をキャンセルしない
        else
          # 意図的な改行のとき \> をキャンセル
          context.skip = false
        end
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
        wrapped_line = true
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
          # @note Fiber.yieldした場合、別の箇所でbufferのfontが変わる可能性があるので、描画ごとに再設定しなければんらない
          use_bitmap_applying_font(target.buffer, context.font) do |buffer|
            # 文字を描画
            rect = buffer.rich_text_size($&)
            buffer.draw_text(x, y + pos_xy_alignmented(lh, rect.height, calign), rect.width, rect.height, $&)
            x += rect.width + (autokerning||0) + tws
            chara_index += $&.size
            frame.times {
              break if context.inputted
              Fiber.yield
            } unless skip || blank?($&)
          end
        end
      end # of case command
    end # of each commands
  end
  
end
