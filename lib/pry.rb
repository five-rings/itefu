=begin
  pryをエラーが出ないように読み込む  
=end
$PROGRAM_NAME = "" unless $PROGRAM_NAME.is_a?(String)
require 'pry'

if defined?(Pry)
  Pry.config.print = Pry::SIMPLE_PRINT
  
  class Pry::Command::Whereami
    alias :expand_path_org :expand_path
    # ファイルIDをファイル名に変換する
    def expand_path(f)
      if f
        code = Itefu::Utility::String.script_name(f)
        expand_path_org("#{$rv2sa_path}\\#{code}")
      else
        expand_path_org(f)
      end
    end
  end
  
  class Pry::Code
    # Coderayを使うとエラーになるので握りつぶす
    def highlighted(*args)
      self
    end
  end
end
