=begin
  読み込んだリソースをキャッシュし、同じリソースを読み込んだ場合の読み込みを省略するためのクラス
=end
class Itefu::Resource::Cache

  class DataInfo
    include Itefu::Resource::ReferenceCounter
    attr_accessor :data, :signature

    def initialize(data, signature)
      super
      @data = data
      @signature = signature
    end
  end
  
  module Exception
    class DataIsAlreadyLoaded < StandardError; end
    class DataIsNotLoaded < StandardError; end
  end

  def initialize
    @data = {}
  end

  # 終了処理
  def finalize
    release_all
  end

  # @return [Boolean] 指定されたIDのリソースが読み込まれているか
  # @param [Fixnum] リソースID
  def loaded?(id)
    @data.has_key?(id)
  end

  # リソースが存在すればそれを取得し、読み込まれていなければ新たに作成する  
  # @note 基本的には fetch_bitmap/fetch_rvdata2 などから使用することを想定している
  # @param [Object] signature 読み込みに使用する識別情報
  # @yield リソースの新規生成を行うブロックを実行する
  # @return [Fixnum] リソースID
  def fetch(signature)
    id = signature.hash
    unless attach(id)
      # リソースが存在しないので新規に作成する
      raw = yield
      store(id, raw, signature) if raw
    end
    id
  end

  # bitmapファイルを読み込む
  # @return [Fixnum] リソースID
  def fetch_bitmap(filename, hue)
    fetch([filename, hue]) { create_bitmap(filename, hue) }
  end

  # rvdata2を読み込む
  # @return [Fixnum] リソースID
  def fetch_rvdata2(filename)
    fetch(filename) { load_rvdata2(filename) }
  end

  # リソースを解放する
  # @param [Fixnum] id リソースID
  # @return [Object] 解放したリソース 
  def release(id, count = 1)
    detach(id, count)
  end

  # 読み込んだデータを全て破棄する
  def release_all
    @data.each_value {|data| release_process(data) }
    @data.clear
  end

  # @return [Object] リソースデータ
  # @param [Fixnum] id リソースID
  def raw_data(id)
    loaded?(id) && @data[id].data || nil
  end
  
  # @return [Object] ロード時に使用したシグネチャ
  # @param [Fixnum] id リソースID
  def signature(id)
    loaded?(id) && @data[id].signature || nil
  end

  # 参照カウンタを上げる
  # @return [Fixnum] 操作後の参照カウンタの値
  # @warning 特殊用途のために用意しているが通常は外部からは使用しない
  def attach(id, count = 1)
    if loaded?(id)
      @data[id].ref_attach(count)
    end
  end
  
  # 参照カウンタを下げる
  # @return [Object] 解放したリソース 
  # @warning 特殊用途のために用意しているが通常は外部からは使用しない
  def detach(id, count = 1)
    if loaded?(id)
      @data[id].ref_detach(count) do
        remove(id)
      end
    end
  end

  def dump
#ifdef :ITEFU_DEVELOP
    ITEFU_DEBUG_OUTPUT_NOTICE self
    @data.each do |id, info|
      ITEFU_DEBUG_OUTPUT_NOTICE("%11x %5d #{info.signature}" % [id, info.count])
    end
    ITEFU_DEBUG_OUTPUT_NOTICE "total: #{@data.size}"
#endif
  end


private

  # 新規にリソースを登録する
  def store(id, data, signature)
    ITEFU_DEBUG_ASSERT(loaded?(id).!, nil, Exception::DataIsAlreadyLoaded)
    @data[id] = DataInfo.new(data, signature)
  end
  
  # 登録されたリソースを削除する
  def remove(id)
    ITEFU_DEBUG_ASSERT(loaded?(id), nil, Exception::DataIsNotLoaded)
    removed = @data.delete(id)
    release_process(removed)
    removed
  end

  # リソースごとの後処理
  # @note 本来であればリソースごとにDecorator Objectを生成し、ポリモルフィズミックに処理すべきであろうが,
  #       リソースひとつごとにオブジェクトを生成するのにかかる時間が無視できないほど大きいので、高速化のために型で分岐している
  def release_process(info)
    case info.data
    when Bitmap
      info.data.dispose
    end
  end
  
  # rvdata2ファイルを読み込む
  def load_rvdata2(filename)
    load_data(filename)
  rescue Errno::ENOENT
    raise
  rescue => e
    ITEFU_DEBUG_OUTPUT_ERROR(e)
    ITEFU_DEBUG_OUTPUT_ERROR(filename)
    nil
  end
  
  # bitmapを作成する
  def create_bitmap(filename, hue)
    b = Itefu::Rgss3::Bitmap.new(filename)
    b.hue_change(hue) if hue && (hue != 0)
    b
  rescue => e
    ITEFU_DEBUG_OUTPUT_ERROR(e)
    ITEFU_DEBUG_OUTPUT_ERROR(filename)
    b = Itefu::Rgss3::Bitmap.empty
    b.ref_attach
    b
  end

end
