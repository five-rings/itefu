=begin
  RPG::BaseItemを読み込むテーブルの実装
=end
# @note 読み込んだ際にnote（メモ)を解析してフラグを立てる
class Itefu::Database::Table::BaseItem < Itefu::Database::Table::Base

  def load(filename)
    super.tap {
      setup_special_flags(filename)
    }
  end

private

  # 特殊フラグを設定した後に呼ばれる
  # @param [String] filename 読み込んだファイル名
  def on_special_flag_set(filename); end
  
  # 特殊フラグをDBの絵要素全体に設定する
  def setup_special_flags(filename)
    @rawdata.each do |entry|
      insert_special_flag(entry) if entry
    end
    on_special_flag_set(filename)
  end

  # 特殊フラグを設定する
  # @param [RPG::BaseItem] entry 特殊フラグを設定するDB内の要素
  def insert_special_flag(entry)
    # DBの中の要素に特殊フラグを格納する変数とそのアクセッサを用意
    entry.instance_variable_set(:@special_flags, {})
    def entry.special_flags; @special_flags; end
    def entry.special_flag(id); @special_flags[id]; end

    # noteを解析して特殊フラグを設定する
    entry.note.each_line do |line|
      command, param = Itefu::Utility::String.parse_note_command(line)
      entry.special_flags[command] = convert_special_flag(command, param) if command
    end
  end

  # 特殊フラグの値を文字列から任意の値に変換する
  # @param [Symbol] command 特殊フラグの種類
  # @param [String|NilClass] param 特殊フラグの設定値
  def convert_special_flag(command, param)
    param || true
  end

end
