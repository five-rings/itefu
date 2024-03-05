=begin
  System.rvdata2を読み込むクラス
=end
class Itefu::Database::Table::System < Itefu::Database::Table::Base
  private :each, :[], :size, :length, :empty?

  def on_loaded(filename)
    apply_window_configure(rawdata)
    apply_sound_configure(rawdata)
  rescue => e
    ITEFU_DEBUG_OUTPUT_WARNING "database-system #{e}"
    raise
  end
  
  def on_unloaded
    apply_sound_configure(nil)
    apply_window_configure(nil)
  end

  # Windowの設定を行う
  def apply_window_configure(system)
    Itefu::Rgss3::Window.default_tone = system && system.window_tone
  end

  # Soundの設定を行う
  def apply_sound_configure(system)
    Itefu::Sound.data_system = system
  end

end
