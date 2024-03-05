=begin
  セーブデータの読み書きを行う
=end
module Itefu::SaveData::Loader

  # @return [SaveData::Base] 作成したセーブデータ
  # @param [Class] klass セーブデータの型
  def self.new_data(klass, *args)
    savedata = klass.new(*args)
    if impl_new_data(savedata)
      savedata
    end
  end

  # @return [SaveData::Base] 読み込んだセーブデータ
  # @param [String] filename ファイル名
  # @param [Class] klass セーブデータの型
  def self.load(filename, klass, *args)
    savedata = klass.new(*args)
    if impl_load(filename, savedata)
      savedata
    end
  end

  # @return [Boolean] セーブの成否
  # @param [String] filename ファイル名
  # @param [SaveData::Base] savedata 保存するセーブデータ
  def self.save(filename, savedata)
    impl_save(filename, savedata)
  end

private

  # @return [Boolean] 成否
  # @param [String] filename ファイル名
  # @param [SaveData::Base] savedata セーブデータ
  def self.impl_load(filename, savedata)
    File.open(filename, "rb") {|file|
      savedata.load(file, filename)
    }
  rescue => e
    ITEFU_DEBUG_OUTPUT_ERROR "failed to load #{filename}"
    ITEFU_DEBUG_OUTPUT_ERROR e.inspect
    false
  end

  # @return [Boolean] 成否
  # @param [String] filename ファイル名
  # @param [SaveData::Base] savedata セーブデータ
  def self.impl_save(filename, savedata)
    File.open(filename, "wb") {|file|
      savedata.save(file, filename)
    }
  rescue => e
    ITEFU_DEBUG_OUTPUT_ERROR "failed to save #{filename}"
    ITEFU_DEBUG_OUTPUT_ERROR e.inspect
    false
  end
  
  # @return [Boolean] 成否
  # @param [SaveData::Base] savedata セーブデータ
  def self.impl_new_data(savedata)
    savedata.new_data
  end

end
