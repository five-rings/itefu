=begin
  登録されたSystem::Baseを管理し呼び出すクラス
=end
class Itefu::System::Manager
  attr_reader :systems      # [Hash<System::Base>] 登録されているシステム
  attr_reader :application  # [Itefu::Application] このシステムマネージャを保持しているMainクラス

  def initialize(application)
    @application = application
    @systems = {}
  end

  # システムクラスを登録する
  # @note クラスの型が自動的に識別子になる
  # @return [System::Base] 生成したシステムクラスのインスタンス
  # @param [Class] klass 登録したいシステムクラス
  # @param [Fixnum] priority 更新プライオリティ(低い値が先に更新, 同じ場合先に登録した方が優先)
  def register(klass, *args, &block)
    register_with_id(klass.klass_id, klass, *args, &block)
  end
  
  # idを指定してシステムクラスを登録する
  # @return [System::Base] 生成したシステムクラスのインスタンス
  # @param [Symbol] id 任意の識別子
  # @param [Class] klass 登録したいシステムクラス
  # @param [Fixnum] priority 更新プライオリティ(低い値が先に更新, 同じ場合先に登録した方が優先)
  def register_with_id(id, klass, *args, &block)
    ITEFU_DEBUG_ASSERT(@systems.has_key?(id).!)
    system = klass.new(self, *args, &block)
    @systems[id] = system
    system
  end

  # 登録してある全てのシステムクラスの終了処理を呼び出し管理リストから除外する  
  def shutdown
    @systems.each_value.reverse_each(&:finalize)
    @systems.clear
  end

  # 登録してある全てのシステムクラスの更新処理を呼び出す  
  def update
    @systems.each_value(&:update)
  end
  
  # @return [System::Base] システムクラスのインスタンス
  # @param [Class|Symbol] id 識別子
  def system(id)
    @systems[id]
  end

end
