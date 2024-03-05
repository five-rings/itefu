=begin
  文字列関連の便利機能  
=end
module Itefu::Utility::String
class << self

  # @return [Boolean] 指定されたコマンドが指定されているか if :symbolの書式の場合
  # @return [String] 指定されたコマンドのパラメータ if :symbol=の書式の場合
  # @param [Symbol] symbol 文字列中に探したいsymbol
  # @param [String] str 探索対象の文字列
  def note_command(symbol, str)
    label = symbol.to_s
    if label[-1] == '='
      if /^\:#{label}([^\r\n]+)/ === str
        $1
      end
    else
      # 二行目以降にもマッチするようにstart_with?を使わない
      /^\:#{label}/ === str
    end
  end
  
  # @return [Integer] note_commandで取得したコマンドの値を整数にして返す
  # @param [Symbol] symbol 文字列中に探したいsymbol
  # @param [String] str 探索対象の文字列
  def note_command_i(symbol, str)
    command = note_command(symbol, str)
    command && (Integer(command) rescue nil)
  end

  # @return [Float] note_commandで取得したコマンドの値を小数にして返す
  # @param [Symbol] symbol 文字列中に探したいsymbol
  # @param [String] str 探索対象の文字列
  def note_command_f(symbol, str)
    command = note_command(symbol, str)
    command && (Float(command) rescue nil)
  end
  
  # @return [Integer] note_commandで取得したコマンドの値をシンボルにして返す
  # @param [Symbol] symbol 文字列中に探したいsymbol
  # @param [String] str 探索対象の文字列
  def note_command_s(symbol, str)
    command = note_command(symbol, str)
    command && command.empty?.! && command.intern
  end

  # @return [Symbol, String|NilClass] 指定されたコマンドとその値
  # @param [String] str 探索対象の文字列
  def parse_note_command(str)
    if /^(?:\:|\*)([\w!\?]+)(?:(?:=([^\r\n]*))?)/ === str
      return $1.intern, $2
    end
  end

  # @return [Integer|Float|String] 数値に変換可能なら変換する
  # @param [String] 変換したい文字列
  # @note 整数→実数→文字列の順に変換可能であればその型で返す
  def to_number(str)
    begin
      Integer(str)
    rescue
      Float(str)
    end
  rescue
    str
  end

  # @return [String] `camelCase`または `UpperCamelCase`を`snake_case`に変換した文字列
  # @param [String] str 変換したい元の文字列
  def snake_case(str)
    str.gsub(/([A-Z0-9]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z][0-9]*)([A-Z])/, '\1_\2').
        downcase
  end

  # @return [String] `snake_case`を`camelCase`に変換した文字列
  # @param [String] str 変換したい元の文字列
  def camel_case(str)
    str.gsub(/(?:_+)([^_])/) { $1.upcase }.sub(/^./) {|word| word.downcase }
  end

  # @return [String] `snake_case`を`UpperCamelCase`に変換した文字列
  # @param [String] str 変換したい元の文字列
  def upper_camel_case(str)
    str.gsub(/(?:_+)([^_])/) { $1.upcase }.sub(/^./) {|word| word.upcase }
  end
  
  # @return [String] 名前空間を除いたクラス/モジュール名を取得する
  def remove_namespace(name)
    name.split("::")[-1] || ""
  end

  # @return [String] ファイル名
  # @param [String] name Scriptsに含まれたファイル識別子
  # @param [String] ext ファイル名につける拡張子名
  def script_name(name, ext = ".rb")
    name.sub(/^\{([0-9]+)\}/) { $RGSS_SCRIPTS[$1.to_i][1] + ext }
  end
  
  # @return [String] 数値をカンマ区切りの文字列にして返す
  # @param [Numeric] number カンマを付与したい数値
  # @param [String] demiliter 区切り文字
  # @param [Fixnum] digit 何桁区切りにするか
  def number_with_comma(number, demiliter = ",", digit = 3)
    case number
    when Integer, String
      number.to_s.gsub(/(\d)(?=(\d{#{digit}})+(?!\d))/, "\\1#{demiliter}")
    when Float
      i, d = number.to_s.split(".", 2)
      i.gsub(/(\d)(?=(\d{#{digit}})+(?!\d))/, "\\1#{demiliter}") << "." << d
    else
      raise TypeError
    end
  end
  
  # @return [Numeric] 文字列からカンマを除去し数値に変換して返す
  # @param [String] number 数値をカンマつきで文字列にしたもの
  # @param [String] demiliter 区切り文字
  def number_without_comma(number, demiliter = ",")
    case number
    when String
      if number.include?(".")
        number.delete(demiliter).to_f
      else
        number.delete(demiliter).to_i
      end
    when Numeric
      number
    else
      TypeError
    end
  end

  # @return [String] 数値の先頭に0を足して指定桁数に揃えた文字列を返す
  # @param [Fixnum] number 変換したい数値
  # @param [Fixnum] digit 何桁の文字列にしたいか
  # @param [Fixnum] base 何進数で表記するか
  # @param [String] leader 空の桁を埋める文字
  # @note digitよりnumberの桁数が大きいときはnumberをそのまま文字列にして返す
  def number_with_leading(number, digit, base = 10, leader = "0")
    n = digit - digit(number, base)
    if n > 0
      leader * n + number.to_s(base)
    else
      number.to_s(base)
    end
  end
  
  # 文字列が指定した長さに収まるよう超過分を省略表記にして返す
  # @return [String] 元の文字列または省略表記にしたもの
  # @param [String] text 必要であれば省略表記にしたい文字列
  # @param [Fixnum] size この長さを超えると省略表記にする
  # @param [String] ellipsis 省略表記にした際に末尾に付け足す文字列
  # @note sizeに6を指定すると、返り値は省略記号も含めて6文字以内に収まる
  def shrink(text, size, ellipsis = "…")
    if text.size > size
      if ellipsis
        if size > ellipsis.size
          text.slice(0, size - ellipsis.size) << ellipsis
        else
          ellipsis
        end
      else
        text.slice(0, size)
      end
    else
      text
    end
  end

  # @return [Fixnum] 数値を文字列として表示する際に何桁になるかを返す
  # @note 負の値の場合は1桁分多く返る
  # @param [Fixnum] number 桁数を取得したい数値
  # @param [Fixnum] base 何進数で表記するか
  def digit(number, base = 10)
    number.to_s(base).length
  end

  # 数値をアルファベットで表現する
  # @return [String] 整数をアルファベットに変換した文字列
  # @param [Fixnum] value 変換する数値
  # @param [Fixnum] base 何進数か
  # @param [String] chara 使用する連続した文字の先頭
  def letter_number(value, chara = nil, base = 26)
    chara ||= 'a'
    return chara * value if base <= 1

    str = ""
    while value > 0
      value -= 1
      str << (chara.ord + value % base).chr
      value /= base
    end
    str.reverse!
  end

  # 数値の小数部だけを文字列として取得する
  # @param [Float|Numeric] value 文字列にしたい数値（整数部は削除される）
  # @param [Integer] offset 切り捨てる桁数
  # @note デフォルトでは 12.345 -> ".345" のように動作する
  def dicimal_part(value, offset = -1)
    v = value.to_f.to_s
    v.slice!(v.index('.') + offset + 1, v.size)
  end

end
end
