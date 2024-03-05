=begin
  設定ファイルの読み込み  
=end
# @note アプリケーション実装のクラスにmix-inして使用する
module Itefu::Config
  DEFAULT_CONVERTED_EXTENSION = ".dat"
  attr_reader :config_filename
  attr_reader :config_extension

  # ファイルを読み込む
  # @param [String] filename ファイル名
  # @param [String] ext 変換後のデータに追加される拡張子  
  # @return [Config] selfを返す
  def load(filename, ext = DEFAULT_CONVERTED_EXTENSION)
    script = impl_load(filename, ext)
    
    @config_filename = filename
    @config_extension = ext

    self.instance_eval(script, filename)
    self
  end
  
  # ロードしたファイルを読み直す
  # @return [Config] selfを返す
  def reload
    load(@config_filename, @config_extension)
  end

  # @return [Config] 自分自身を返す
  def config; self; end

private

  # ファイル読み込みの内部実装
  # @return [String] 読み込んだファイルの内容
  # @param [String] filename ファイル名
  # @param [String] ext 変換後のデータに追加される拡張子  
  # @note ITEFU_DEVELOP時は, filenameがあればそれを読み、なければextを付与したファイルを読み込む. extを付与する場合のみ暗号化ファイルから読み込める.
  #       filenameはただのテキストファイルで、filename.extのファイルは文字列をMarshal.dumpしたファイルでなければならない.
  def impl_load(filename, ext)
#ifdef :ITEFU_DEVELOP
    if File.exists?(filename)
      File.open(filename, "r") {|f|
        f.read
      }
    else
#endif
      load_data(filename + ext)
#ifdef :ITEFU_DEVELOP
    end
#endif
  end

end
