=begin
  ユニットの基底クラス
=end
class Itefu::Unit::Base
  attr_reader :manager      # [Unit::Manager] このユニットを管理しているマネージャ
  attr_accessor :priority   # [Fixnum] 優先度

  # @return [Symbol] ユニットのID
  # @note デフォルトではクラス名を使用するので必要に応じてオーバーライドする
  def unit_id; self.class.unit_id; end

  # @return [Symbol] デフォルトのユニットID
  def self.unit_id; @unit_id ||= name.intern; end
  
  # @return [Boolean] Unit::Managerにatatchされているか
  def attached?; detached?.!; end

  # @return [Boolean] Unit::Managerからdetachされているか
  def detached?; @manager.nil?; end

private
  # @return [Fixnum] プライオリティの初期値を定義する
  # @note 派生先で実装する
  def default_priority; raise Itefu::Exception::NotImplemented; end

  # Managerからインスタンス生成時に一度呼ばれる
  def on_initialize(*args); end

  # Managerからインスタンス破棄時に一度呼ばれる
  def on_finalize; end
  
  # Managerから毎フレーム一度呼ばれる更新処理
  def on_update; end

  # Managerから毎フレーム一度呼ばれる描画処理
  def on_draw; end
  
  # Managerに割り当てられた際に一度呼ばれる
  def on_attached; end
  
  # Managerから取り除かれた際に一度呼ばれる
  def on_detached; end

  # @param [Unit::Manager] manager このユニットを管理するmanager
  def initialize(manager, *args, &block)
    @signal_callbacks = {}
    @manager = manager
    @priority = default_priority
    on_initialize(*args, &block)
  end
  
public
  # シグナルを処理する
  # @note callbackが指定されていればそれを呼び,
  #       on_value_signaled が定義されていればそれも呼ぶ
  # @param [Symbol] value シグナルの識別子
  # @param [Array] args 任意のパラメータ
  def signal(value, *args)
    callback = @signal_callbacks[value]
    callback.call(self, *args) if callback

    method = :"on_#{value}_signaled"
    self.send(method, *args) if self.respond_to?(method)
  end
  
  # signalに対応するコールバックを設定する
  # @param [Symbol] value 対象のシグナルの識別子
  def signaled(value, &block)
    @signal_callbacks[value] = block
  end

  # 終了処理
  def finalize
    on_finalize
  end
  
  # 更新処理
  def update
    on_update
  end
  
  # 描画処理
  def draw
    on_draw
  end
  
  # マネージャに割り当てた際に呼ぶ
  # @param [Unit::Manager] manager 割り当てられたマネージャ
  def attached(manager)
    @manager = manager
    on_attached
  end
  
  # マネージャから取り除いた際に呼ぶ
  def detached
    on_detached
    @manager = nil
  end

end
