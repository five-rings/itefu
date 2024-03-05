=begin
  データベースに読み込むデータ（テーブル）の基底クラス
=end
class Itefu::Database::Table::Base
  include Enumerable    # イテレーションを可能にする
  attr_reader :rawdata  # [Array<Object>] 読み込んだデータ

private
  # データを読み込んだ後に呼ばれる
  # @param [String] filename 読み込んだファイル名
  def on_loaded(filename); end

  # データを解放する際に呼ばれる
  def on_unloaded; end

public
  # データを読み込む
  # @param [String] filename 読み込むファイル名
  def load(filename)
    @rawdata = impl_load(filename)
    on_loaded(filename)
    @rawdata
  rescue => e
    ITEFU_DEBUG_OUTPUT_WARNING "load database #{e}"
    nil
  end
  
  # データを解放する
  def unload
    on_unloaded
  end

  # --------------------------------------------------
  # Array風にアクセスするためのアクセッサ
  
  def each(&block); @rawdata.each(&block); end
  def [](index); @rawdata[index]; end
  def size; @rawdata.size; end
  def length; @rawdata.length; end
  def empty?; @rawdata.empty?; end

private

  # データを読み込む
  # @param [String] filename 読み込むファイル名
  def impl_load(filename)
    load_data(filename)
  end

end
