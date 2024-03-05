=begin
  多言語対応のためのメッセージ定義データをあらわすクラス
=end
class Itefu::Language::Message
  include Itefu::Resource::ReferenceCounter
  include Itefu::Resource::Loader
  attr_reader :locale     # [Language::Locale] 読み込んでいる言語
  attr_reader :filename   # [String] 読み込んでいるファイル

  # @param [String] path 定義ファイル置き場のパス
  # @param [String] filename 読み込むファイル名
  # @param [Symbol] locale 読み込む言語
  def initialize(path, filename, locale)
    super
    id = load_impl(path, filename, locale)
    @data = resource_data(id)
  end
  
  def finalize
    @id_last_load = nil
    @data = nil
    release_all_resources
  end

  # @param [String] path 定義ファイル置き場のパス
  # @param [Language::Locale] locale 読み込む言語
  # @return [Hash] 読み込んだデータ
  # @note 違う言語の場合にのみ再度読み込む
  def reload(path, locale)
    return unless (locale != self.locale)
    id = load_impl(path, filename, locale)
    @data = resource_data(id)
  end

  # @return [String] 定義された文章
  # @param [Symbol] id 文章の識別子
  def text(id)
    @data[id]
  end
  
  # @return [Enumrator] idを繰り返し与える
  def each_id(&block)
    if block
      @data.each_key(&block)
    else
      @data.each_key
    end
  end

private

  # @return [Hash] 読み込んだデータ
  # @param [String] path 定義ファイル置き場のパス
  # @param [String] filename 読み込むファイル名
  # @param [Symbol] locale 読み込む言語
  def load_impl(path, filename, locale)
    release_resource(@id_last_load) if @id_last_load
    @filename = filename
    @locale = locale
    begin
      # 言語ごとのファイルがあればそれを読む
      @id_last_load = load_rvdata2_resource("#{path}/#{locale}/#{filename}")
    rescue Errno::ENOENT
      # 言語ごとのがなければ、共通のファイルを読む
      @id_last_load = load_rvdata2_resource("#{path}/#{filename}")
    end
  end

end
