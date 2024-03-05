=begin
  サウンド関連/SystemManagerに登録するためのインターフェイス
=end
module Itefu::Sound::Manager

  def self.dump_log(out); end
  
  def self.klass_id; self; end

  def self.new(manager)
    initialize(manager)
    Itefu::Sound::Manager
  end

  # Managerに登録された際に呼ばれる
  def self.initialize(manager)
    Itefu::Sound.reset
    Itefu::Sound.environment = Itefu::Sound::Environment.new
  end

  # Managerから取り除かれた際に呼ばれる
  def self.finalize
    if Itefu::Sound.environment
      Itefu::Sound.environment.finalize
      Itefu::Sound.environment = nil
    end
  end

  # Managerから毎フレーム呼ばれる
  def self.update
    Itefu::Sound.update
  end

end
