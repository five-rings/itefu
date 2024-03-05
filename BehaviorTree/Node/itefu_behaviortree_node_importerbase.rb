=begin
  BehaviorTree/Node/外部から読み込んだノードを子として接続する
=end
class Itefu::BehaviorTree::Node::ImporterBase < Itefu::BehaviorTree::Node::Decorator
  include Itefu::BehaviorTree::Node
  attr_reader :script_id  

  # @return [String] 実行するスクリプトコード
  # @param [Object] script_id 定義ファイルの識別子
  # @note 継承先で実装する
  def script_text(script_id); raise Exception::NotImplemented; end

  # @param [Object] script_id 定義ファイルの識別子
  def initialize(script_id)
    @script_id = script_id
    super
  end

  def node_joined(*args)
    super
    clear_child
    setup_from_script
  end


private

  def setup_from_script
    script = script_text(@script_id)
    importer = self
    instance_eval(script) if script
  rescue => e
    show_exception("#{self.class}##{@script_id}", e)
  end

end
