=begin
  Layoutシステム/RGSS3の制御文字を処理する文字列描画
=end
module Itefu::Layout::Control::FormatString
  extend Itefu::Layout::Control::Bindable::Extension
  include Itefu::Layout::Definition
  include Itefu::Rgss3::Definition::MessageFormat
  attr_bindable :text_word_space  # [Fixnum] 文字間隔
  attr_bindable :icon_space       # [Fixnum] アイコンの隙間
  attr_bindable :text_line_space  # [Fixnum] 行間隔
  attr_bindable :hanging          # [Boolean] ぶら下がり処理を行うか
  attr_bindable :word_to_fill     # [Fixnum] 何文字欠けた行まで伸張するか

  # @return [String] アクターの名前を返す
  def actor_name(actor_id); raise Exception::NotImplemented; end
  # @return [String] パーティメンバーの名前を返す
  def member_name(member_index); raise Exception::NotImplemented; end
  # @return [String] 変数の内容を返す
  def variable(index); raise Exception::NotImplemented; end
  # @return [String] 通貨の単位を返す
  def currency_unit; raise Exception::NotImplemented; end

  # @return [Boolean] DrawingInfoの再計算が必要ない状態か
  def drawing_info_valid?; @drawing_info.commands; end

  # word_to_fill未設定時の値
  DEFAULT_WORD_TO_FILL = 1

  # 空白文字
  BLANK_CHARACTERS = " 　"
  # 行頭禁則文字
  LINE_HEAD_PROHIBITIONS = "!?！？々ゝ・：；:;.,、。．，,）)]｝〕〉》」』】〙〗〟’”｠»"
  # ぶらさがり文字
  HANGING_CHARACTERS = ".,、。．，,"
  # 行末禁則文字
  LINE_TAIL_PROHIBITIONS = "（([｛〔〈《「『【〘〖〝‘“｟«"
  # 部分除去可能な分離禁則文字
  OMITTABLE_SEPARATION_PROHIBITIONS = "…―"
  # 分離禁則
  # 単語として扱う文字を指定し、単語中では改行しないことで、分離禁則が適用されるようにする
  # @note アルファベット or 数値 or 連続する感嘆疑問符 or ... or -- or 任意の1文字
  WORD_PATTERN = /(?:[A-Za-z](?:[A-Za-z_\-]*[A-Za-z])?[\.\,\:\;\!\?]?)|(?:\-?\d(?:[0-9\,\.\:]*\d)?%?)|[\!\?！？]+|\.+|\-+|./

  # Commandと同じ名前で値が数値の定数
  module FixnumedCommand
    INVALID = 0
  end
  Utility::Module.declare_enumration(FixnumedCommand, Command.constants, 1)
  # Commandの文字列からFixnumedCommandの数値を取得するテーブル
  COMMAND_TO_FIXNUM = Hash[Utility::Module.const_values(Command).map.with_index(1) {|value, i|
                        [value, i]
                      }]
  
  # 独自定義のコマンド
  module CustomCommand
    NEW_LINE  = :new_line   # 改行
    LINE_WRAP = :line_wrap  # 自動折り返し
  end

  # 描画するための情報
  DrawingInfo = Struct.new(
    :commands,          # [Array] テキストをパースして作った描画情報
    :line_words,        # [Array] 各行の文字数
    :line_widths,       # [Array] 各行の幅
    :line_heights,      # [Array] 行の高さ
    :width,             # [Fixnum] 描画領域全体の幅
    :height,            # [Fixnum] 描画領域全体の高さ
  )

  DUMMY_EMPTY_STRING = "".freeze
  

  def initialize(*args)
    super
    @drawing_info = DrawingInfo.new(nil, [], [], [], 0, 0)
    self.text_word_space = 0
    self.icon_space = 2
    self.text_line_space = 0
  end

  # 属性変更時の処理
  def binding_value_changed(name, old_value)
    case name
    when :text_word_space
      if drawing_info_valid?
        # 各行の文字幅を再計算する
        diff = self.test_word_space - old_value
        info = @drawing_info
        info.line_words.each.with_index do |word, i|
          info.line_widths[i] += (word - 1) * diff if word > 1
        end
        info.width = info.line_width.max
      end
    when :text_line_space
      if drawing_info_valid?
        # 全体の高さだけ変わるので更新する
        info = @drawing_info
        info.height = info.line_heights.inject(&:+) + (info.line_heights.size - 1) * self.text_line_space
      end
    when :hanging
      # ぶら下がり行だけ再計算するにしても、ぶら下がり分のサイズを覚えておかなければならないことと、
      # 描画後に動的にぶら下がりだけを切り替えたいようなことはないと思われるので、全部計算しなおすことにする
      invalidate_drawing_info
    end
    super
  end

   # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :text_word_space, :text_line_space, :hanging
      (width != Size::AUTO) && (height != Size::AUTO)
    when :word_to_fill
      true
    else
      super
    end
  end
  
  def blank?(chara)
    chara && chara.size == 1 && BLANK_CHARACTERS.include?(chara)
  end

  # @return [Boolean] 行末禁則文字か
  def line_head_prohibition?(chara)
    # chara が単語の場合でも、!?は行末禁則されてほしいので
    chara && LINE_HEAD_PROHIBITIONS.include?(chara[0])
  end

  # @return [Boolean] ぶらさがり文字か
  def hanging?(chara)
    chara && chara.size == 1 && HANGING_CHARACTERS.include?(chara)
  end
  
  # @return [Boolean] 行頭禁則文字か
  def line_tail_prohibition?(chara)
    chara && chara.size == 1 && LINE_TAIL_PROHIBITIONS.include?(chara)
  end

  # @return [Boolean] 除去可能な文字か
  # @note 分離禁則の後半が行頭にきたときに除去するのに使われる
  def omittable?(chara, prev)
    chara && chara.size == 1 && (chara == prev) && OMITTABLE_SEPARATION_PROHIBITIONS.include?(chara)
  end
  
  # @return [Boolean] 行を均等割りする必要があるか
  def equal_space?(cw, space, word, wtf)
    space < 0 ||
    space > 0 && (space <= (wtf || DEFAULT_WORD_TO_FILL) * (cw - space) / word)
  end
  
  # drawing_infoを無効にする
  def invalidate_drawing_info
    @drawing_info.commands = nil
  end
  
  def command_id(command)
    command & 0xf
  end
  
  def command_index(command)
    (command >> 4) - 1
  end

  # 変数で置換されるものを処理する
  def replace_text(text)
    return "" unless text
    
    text = text.clone
    text.gsub!(CRLF, NEW_LINE)
    text.gsub!(CommandPattern::ACTOR_NAME) {
      actor_name((Integer($1) rescue nil))
    }
    text.gsub!(CommandPattern::MEMBER_NAME) {
      member_name((Integer($1) rescue nil))
    }
    text.gsub!(CommandPattern::VARIABLE) {
      variable((Integer($1) rescue nil))
    }
    text.gsub!(CommandPattern::CURRENCY_UNIT) {
      currency_unit
    }
    text
  end
  
  def parse_text(text)
    # 改行 or 制御文字 or 通常の文字 を要素にした配列に変換する
    text.scan(/#{NEW_LINE}|#{Regexp.escape(COMMAND_PREFIX)}[^#{Regexp.escape(COMMAND_PREFIX)}](?:\[\d+\])?|(?:[^#{NEW_LINE}#{Regexp.escape(COMMAND_PREFIX)}]|#{Regexp.escape(ESCAPED_PREFIX)})+/o).
         map {|command|
           case command
           when /^#{Regexp.escape(COMMAND_PREFIX)}([^#{Regexp.escape(COMMAND_PREFIX)}])(?:\[(\d+)\])?$/o
             # 制御文字
             # 下位4bitに制御文字の識別子、それ以上のbitに添え字の数値を格納する
             # 添え字は、指定なしなら0、指定がある場合は 実際の値 +1 を格納する
             (COMMAND_TO_FIXNUM[$1] + ($2 && (Integer($2) + 1 << 4) || 0)) rescue FixnumedCommand::INVALID
           when NEW_LINE
             CustomCommand::NEW_LINE
           else
             # 文字列
             command.gsub!(ESCAPED_PREFIX, COMMAND_PREFIX)
             command
           end
         }
  end

  def update_drawing_info(buffer, text)
    info = @drawing_info
    info.commands = parse_text(replace_text(text))
    info.line_words.clear
    info.line_widths.clear
    info.line_heights.clear

    font_size = buffer.font.size
    line_word = line_width = line_height = 0
    tws = self.text_word_space
    ics = self.icon_space
    hng = self.hanging
    inbound = true
    width_to_wrap = (self.width != Size::AUTO || self.max_width) && self.desired_content_width
 
    info.commands.each.with_index do |command, command_index|
      case command
      when Fixnum
        # 制御文字
        case command & 0x0f
        when FixnumedCommand::TO_BIGGER
          index = command_index(command)
          buffer.font.size += (index < 0) ? FONT_SIZE_SCALE : index
          next
        when FixnumedCommand::TO_SMALLER
          index = command_index(command)
          buffer.font.size -= (index < 0) ? FONT_SIZE_SCALE : index
          next
        when FixnumedCommand::ICON
          # アイコンサイズはそのときのフォントサイズに合わせる
          rect = Itefu::Rgss3::Rect::TEMP
          rect.width  = buffer.font.size
          rect.height = buffer.font.size
          # 文字として扱う
          command = DUMMY_EMPTY_STRING
          # next  # 通常の文字処理に任せる
        else
          next
        end
      when CustomCommand::NEW_LINE, CustomCommand::LINE_WRAP
        # 改行する
        unless inbound
          # 行頭禁則を押し込んだまま文章が終わってしまったので、今回の改行をLINE_WRAPに変更する
          info.commands[command_index] = CustomCommand::LINE_WRAP
          inbound = true
        end

        info.line_words << line_word
        if line_word > 0
          info.line_widths << (line_width - tws)
          info.line_heights << line_height
        else
          info.line_widths << 0
          info.line_heights << buffer.font.size
        end
        line_word = line_width = line_height = 0
        next
      end


      # 文字の処理をする
      # アイコンの場合 chara.nil? になるので一文字目だけはループの外で特殊処理する
      chara_index = 0
      if WORD_PATTERN === command
        chara = $&
        chara_size = $&.size
        rect = buffer.rich_text_size(chara)
      else
        chara = nil
        chara_size = 1
      end
      prev_chara = prev_width = prev_height = 0

      begin # of while chara
        # 折り返しのチェックをしながら文字を追加していく
        if width_to_wrap &&                               # 自動改行の必要があり
            (line_word > 0) &&                            # 1文字は表示していて
            (line_width + rect.width > width_to_wrap)     # 文字がはみ出している
          # はみだしているので自動折り返しするかチェックする
          if line_head_prohibition?(chara) && inbound &&  # 行頭禁則文字で、この文字以前にはまだ枠からはみ出していなかった
              (chara_size == 1 ||                         # 1文字の単語なら無条件で行頭禁則を適用する
                (w = line_width + rect.width) &&          # 複数文字の単語の場合...
                (w / (w - width_to_wrap)) >= line_word    # はみ出しがおよそ1文字分なら行頭禁則を適用する
              )
            # 行頭禁則なので改行処理はしない
            if hng && hanging?(chara)
              # ぶら下がり文字の分は文字サイズに数えない
              rect.width = 0
            end
            # はみ出したのを覚えておく
            inbound = false
          else
            # 自動改行
            if chara_index > 0
              if line_tail_prohibition?(prev_chara) || blank?(prev_chara)
                # 前の文字が行末禁則の場合は、次の行に送り込む
                chara_index -= 1
                line_word -= 1
                line_width = prev_width
                line_height = prev_height
              end
              # このコマンドの文字列を改行より前の分だけに切り詰める
              tail = command.slice!(chara_index..-1)            # @hack 現在のコマンドの内容も書き換えている
              tail.slice!(0) if omittable?(chara, prev_chara)   # 分離禁則で削除可能な文字を消す
              tail.slice!(0) if blank?(tail[0])                 # 自動改行したあと先頭が空白になるときは除去
              # 次のコマンドに改行と未処理分の文字列を積む
              # @hack array.each ではイレテーションごとにサイズをチェックしているので、現在位置より後ろに足す分には正常に動作する
              if tail.empty?
                info.commands.insert(command_index + 1, CustomCommand::LINE_WRAP)
              else
                info.commands.insert(command_index + 1, CustomCommand::LINE_WRAP, tail)
              end
            else
              # アイコン or 最初の1文字 がはみ出した場合は前に改行を挟むしかない
              info.commands.insert(command_index, CustomCommand::LINE_WRAP)
              command = CustomCommand::LINE_WRAP
            end
            
            # 改行処理を挿入したのではみ出しを解除する
            inbound = true
            # 残りの文字列はコマンドに積んだので、文字の処理を中断する
            break
          end
        end # of if wrap
 
        # 行末に追加する
        prev_width  = line_width
        prev_height = line_height
        if rect.width > 0
          line_word  += 1
          line_width += rect.width + (chara && tws || ics)
        end
        line_height = Utility::Math.max(rect.height, line_height)

        # 次の文字へ
        chara_index += chara_size
        prev_chara = chara
        if WORD_PATTERN.match(command, chara_index)
          chara = $&
          chara_size = chara.size
          rect = buffer.rich_text_size(chara)
        else
          # chara = nil
          break
        end
      end while true # while chara

      # @hack アイコンや前に文字がないときなど、現在の位置に改行を追加することがあるので、その際は現時点をやり直す
      redo if command == CustomCommand::LINE_WRAP
    end # of commands.each

    if line_word > 0
      # 最後の行の分を追加する
      info.line_words << line_word
      info.line_widths << (line_width - tws)
      info.line_heights << line_height
    else
      # 最後の行が改行のみなので削除する
      case info.commands[-1]
      when CustomCommand::NEW_LINE, CustomCommand::LINE_WRAP
        info.commands.pop
      end
    end
    # 全体のサイズを計算する
    info.width  = info.line_widths.max || 0
    info.height = info.line_heights.inject(0, &:+) + self.text_line_space * Utility::Math.max(0, info.line_heights.size - 1)

    # @hack 改行コードの処理を行う
    # LINE_WRAPを見つけたら、その直前の改行の次にLINE_WRAPを挿入し、自身は改行に書き換える
    # 改行はすべて NEW_LINE になり、折り返しの必要な行の前には LINE_WRAP が挿入されることになる
    cursor = 0
    info.commands.each.with_index do |command, command_index|
      case command
      when CustomCommand::NEW_LINE
        cursor = command_index + 1
      when CustomCommand::LINE_WRAP
        info.commands[command_index] = CustomCommand::NEW_LINE
        info.commands.insert(cursor, CustomCommand::LINE_WRAP)
      end
    end

    # フォント設定が変わった可能性があるので元に戻す
    # @note サイズ計算ではフォント色はかえないので、色は戻さなくてよい
    buffer.font.size = font_size
  end

end
