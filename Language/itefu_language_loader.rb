=begin
  言語ごとのメッセージ定義ファイルを読み込む
=end
module Itefu::Language::Loader
  attr_accessor :locale     # [Language::Locale] 現在のデフォルト言語

  # @return [Class] load_messageで生成するインスタンスのクラス
  def message_klass; Itefu::Language::Message; end

  def initialize(*args)
    @messages = {}
    super
  end

  # @return [Boolean] メッセージ定義ファイルを読み込んでいるか
  # @param [Symbol] id メッセージの識別子
  def loaded_message?(id)
    @messages.has_key?(id)
  end

  # メッセージ定義ファイルを読み込む
  # @param [Symbol] id 読み込むメッセージに対する任意の識別子
  # @param [String] path 定義ファイル置き場のパス
  # @param [String] filename 読み込むファイル名
  # @param [Language::Locale] locale 読み込む言語, 指定しなければ現在のデフォルトが読み込まれる
  # @return [Language::Message] 読み込んだメッセージデータ
  def load_message(id, path, filename, locale = nil)
    if loaded_message?(id)
      @messages[id].ref_attach
      @messages[id]
    else
      @messages[id] = message_klass.new(path, filename, locale || self.locale || Itefu::Language.locale)
    end
  end

  # 読み込んだメッセージ定義ファイルを解放する
  # @param [Symbol] id 解放するメッセージの識別子
  # @raise [ArgumentError] 登録していないidに対して解放しようとした際に送出される
  # @return [Language::Message] 解放したメッセージ
  def release_message(id)
    raise ArgumentError unless loaded_message?(id)
    @messages[id].ref_detach do
      @messages[id].finalize
      @messages.delete(id)
    end
  end
  
  # すべてのメッセージを解放する
  def release_all_messages
    @messages.each_value(&:finalize)
    @messages.clear
  end

  # 既に読み込んだメッセージ定義ファイルを別の言語設定で読み直す  
  # @param [String] path 定義ファイル置き場のパス
  # @param [Language::Locale] locale 読み込む言語, 指定しなければ現在のデフォルトが読み込まれる
  def reload_messages(path, locale = nil)
    locale ||= self.locale || Itefu::Language.locale
    @messages.each_value do |message|
      message.reload(path, locale)
    end
  end
  
  # @return [String] 読み込んだメッセージ定義ファイル内の文を取得する
  # @param [Symbol] id 読み込んだファイルの識別子
  # @param [Symbol] test_id ファイル内の文章の識別子
  def message(id, text_id)
    ITEFU_DEBUG_ASSERT(loaded_message?(id), "unloaded message `#{id.to_s}' for #{self}")
    @messages[id].text(text_id)
  end

end
