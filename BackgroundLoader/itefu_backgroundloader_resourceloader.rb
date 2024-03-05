=begin
  Itefu::Resource::LoaderのWrapper
=end
module Itefu::BackgroundLoader::ResourceLoader
  include Itefu::Resource::Loader
  
  # 読み込んだリソースを全て解放する
  # @warning Resource::Loaderと同じくこのモジュールでloadした際に呼ぶのを忘れないように
  # def release_all_resources
    # super
  # end

  # extend時に変数を初期化する
  def self.extended(object)
    Itefu::Resource::Loader.extended(object)
  end

  # Bitmapの読み込みをリクエストする
  # @param [String] filename ファイル名
  # @param [Fixnum] hue 色相
  def queue_to_load_bitmap(filename, hue = nil)
    bgloader = $itefu_application.system(Itefu::BackgroundLoader::Manager)
    ITEFU_DEBUG_ASSERT(bgloader)
    bgloader.queue_to_load_bitmap(self, filename, hue)
  end

  # rvdata2の読み込みをリクエストする
  # @param [String] filename ファイル名
  def queue_to_load_rvdata2(filename)
    bgloader = $itefu_application.system(Itefu::BackgroundLoader::Manager)
    ITEFU_DEBUG_ASSERT(bgloader)
    bgloader.queue_to_load_rvdata2(self, filename)
  end

end