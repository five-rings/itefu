=begin  
  iniファイルの操作関連
=end
module Itefu::Win32
  GetPrivateProfileInt = Win32API.new('kernel32', 'GetPrivateProfileInt', ['P','P','L','P'], 'L')
  GetPrivateProfileString = Win32API.new('kernel32', 'GetPrivateProfileString', ['P','P','P','P','L','P'], 'L')
  WritePrivateProfileString = Win32API.new('kernel32', 'WritePrivateProfileString', ['P','P','P','P'], 'L')

class << self
  
  # iniファイルから数値を読み込む
  # @param [String] file 読み込むiniのファイル名
  # @param [String] section iniファイル内のセクション名
  # @param [String] key 読み込むキー名
  # @param [Fixnum] default 読み込めない場合のデフォルト値
  # @return [Fixnum|NilClass] 読み込んだ値
  # @note defaultを指定しなかった場合、値が存在しなければNilClassを返す
  def getPrivateProfileInt(file, section, key, default = nil)
    if default
      GetPrivateProfileInt.call(section, key, default, "#{getModuleFullPath}\\#{file}")
    else
      existsPrivateProfileKey?(file, section, key)
    end
  end

  # iniファイルから数値を読み込む
  # @param [String] file 読み込むiniのファイル名
  # @param [String] section iniファイル内のセクション名
  # @param [String] key 読み込むキー名
  # @param [Fixnum] default 読み込めない場合のデフォルト値
  # @return [Fixnum|NilClass] 読み込んだ値
  # @note defaultを指定しなかった場合、空文字を返す
  def getPrivateProfileString(file, section, key, default = nil)
    buffer = " " * 128
    GetPrivateProfileString.call(section, key, default || "", buffer, buffer.size-1, "#{getModuleFullPath}\\#{file}")
    buffer.strip!
    buffer
  end
  
  # iniファイルに数値を書き込む
  # @param [String] file 書き込むiniのファイル名
  # @param [String] section iniファイル内のセクション名
  # @param [String] key 書き込むキー名
  # @param [Fixnum] value 書き込む値
  # @return [Fixnum] 書き込みに成功すると0を返す
  def writePrivateProfileInt(file, section, key, value)
    WritePrivateProfileString.call(section, key, value.to_s, "#{getModuleFullPath}\\#{file}")
  end

  # @return [NilClass|Fixnum] iniファイルにキーが存在するかチェックする
  # @note キーが存在すればその値を、存在しなければNilClassを返す
  def existsPrivateProfileKey?(file, section, key)
    fullpath = "#{getModuleFullPath}\\#{file}"
    v = GetPrivateProfileInt.call(section, key, 0, fullpath)
    (v == GetPrivateProfileInt.call(section, key, 1, fullpath)) ? v : nil
  end

end
end
