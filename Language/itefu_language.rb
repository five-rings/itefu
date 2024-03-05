=begin
  多言語対応に関するクラスなど  
=end
module Itefu::Language
  # 言語と地域
  module Locale
    JA_JP = :ja_jp    # 日本語
    EN_US = :en_us    # アメリカ英語
    EN_GB = :en_gb    # イギリス英語
    FR_FR = :fr_fr    # フランス語
    DE_DE = :de_de    # ドイツ語
    IT_IT = :it_it    # イタリア語
    ES_ES = :es_es    # スペイン語
    # 上記の例のようにタイトル側で拡張して使用する
  end
  
  @@locale = nil
  
  # ゲーム全体の言語設定を行う
  def self.locale=(value)
    @@locale = value
  end
  
  # ゲーム全体の言語設定を取得する
  def self.locale
    @@locale
  end

end
