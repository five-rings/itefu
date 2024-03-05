=begin
  System::Managerに登録して実行するクラスの基底
=end
class Itefu::System::Base
  attr_reader :manager  # [System::Manager] このシステムを管理しているマネージャ
  
  # @return [Object]bシステムの識別に使用する
  def self.klass_id; self; end

  # @return [Itefu::Application]
  def application; manager.application; end

  # デバッグ情報を出力する
  # @param [IO] out 出力先
  # @note 派生先で必要に応じて実装する
  def dump_log(out); end

  # このシステムが管理するインスタンスを生成する
  # @return [Object] 生成したインスタンス
  # @param [Class] klass インスタンスを生成したいクラス
  def create_instance(klass, *args, &block)
    klass.new(self, *args, &block)
  end

private
  # --------------------------------------------------
  # 継承先で必要に応じてover-rideする

  # インスタンス生成後に一度だけ呼ばれる
  def on_initialize(*args); end
  
  # インスタンス破棄時に一度だけ呼ばれる
  def on_finalize; end
  
  # 毎フレーム一度だけ呼ばれる
  def on_update; end


public
  # --------------------------------------------------
  # 以下はScene::Managerから呼ばれる

  def initialize(manager, *args, &block)
    @manager = manager
    on_initialize(*args, &block)
  end

  def finalize
    on_finalize
  end

  def update
    on_update
  end

end
