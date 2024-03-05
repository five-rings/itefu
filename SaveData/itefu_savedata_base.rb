=begin
  セーブデータの基底クラス
=end
class Itefu::SaveData::Base
  attr_reader :name   # [String] 読み込んだデータの名前

  # @return [Boolean] 新規データ作成の成否
  def new_data
    @name = nil
    on_new_data
  end

  # @return [Boolean] 読み込みの成否
  # @param [IO] 入力元
  # @param [String] name 読み込んだデータの名前
  def load(io, name)
    if ret = on_load(io, name)
      @name = name
    end
    ret
  end

  # IOに出力する際に呼ばれる
  # @return [Boolean] 保存の成否
  # @param [IO] 出力先
  # @param [String] name 保存するデータの名前
  def save(io, name)
    if ret = on_save(io, name)
      @name = name
    end
    ret
  end

private
  # 新規データを作成する際に呼ばれる
  # @return [Boolean] 作成の成否
  def on_new_data
    raise Itefu::Exception::NotImplemented
  end

  # IOから読み込む際に呼ばれる
  # @return [Boolean] 読み込みの成否
  # @param [IO] 入力元
  # @param [String] name 読み込んだデータの名前
  def on_load(io, name)
    raise Itefu::Exception::NotImplemented
  end

  # IOに出力する際に呼ばれる
  # @return [Boolean] 保存の成否
  # @param [IO] 出力先
  # @param [String] name 保存するデータの名前
  def on_save(io, name)
    raise Itefu::Exception::NotImplemented
  end
  
  # 圧縮した結果を返す
  def deflate(data)
    Zlib::Deflate.deflate(Marshal.dump(data))
  end
  
  # 圧縮した結果をioにdumpする
  def deflate_dump(data, io)
    Marshal.dump(deflate(data), io)
  end
  
  # 展開した結果を返す
  def inflate(data)
    Marshal.load(Zlib::Inflate.inflate(data))
  end
  
  # ioからloadした結果を展開する
  def inflate_load(io)
    inflate(Marshal.load(io))
  end

end
