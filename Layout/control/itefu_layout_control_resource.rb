=begin
  Layoutシステム/リソースの読込と解放を行う
=end
module Itefu::Layout::Control::Resource
  include Itefu::Resource::Loader
  attr_accessor :auto_release
  
  # extend時に変数を初期化する
  def self.extended(object)
    if object.uninitialized?
      object.initialize_resource_variables
    end
  end

  # 終了処理
  def finalize
    super
    release_all_resources
  end
  
  # 画像を読み込む
  # @return [Fixnum] リソースID
  # @param [String] filename ファイル名
  # @param [Fixnum] hue 色相
  def load_image(filename, hue = nil)
    if auto_release
      load_bitmap_resource(filename, hue).tap {|id|
        release_image
        @id_last_loaded = id
      }
    else
      load_bitmap_resource(filename, hue)
    end
  end
  
  # 最後に読んだ画像を解放する
  def release_image
    if @id_last_loaded
      release_resource(@id_last_loaded)
      @id_last_loaded = nil
    end
  end

  # @return [Object] 読み込んだリソースのデータを返す  
  # @param [Fixnum|Object] リソースの識別子または画像そのもの
  def data(id)
    case id
    when Fixnum
      resource_data(id)
    else
      id
    end
  end
  
  # @return [String] 読み込んだリソースのファイル名を返す
  # @param [Fixnum] リソースの識別子
  def filename(id)
    signature = resource_signature(id)
    signature && signature[0]
  end

end
