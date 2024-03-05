=begin
  BehaviorTree/Node/子ノードのうち一つをランダムに実行するノード
  @note 子ノードにweightが設定されていれば、重み付け選択を行う
  @note 数値が大きいほど重く扱う
=end
class Itefu::BehaviorTree::Node::Random < Itefu::BehaviorTree::Node::Composite

  # @param [Proc] rand_proc 擬似乱数を生成するProc
  def on_initialize(rand_proc = nil)
    @rand_proc = rand_proc if rand_proc
    # 同じindexの子ノードまでの重みの合計
    @weights = []
  end

  # 子ノード接続時に重みを設定する
  def join_node(*args)
    child = super
    weight = (child.weight rescue 1)
    @weights << (sum_of_weights + weight)
    child
  end

  # 子ノード切断時に重みも削除する
  def clear_children
    super
    @weights.clear
  end
  
  # @return [Integer] 重みの合計
  def sum_of_weights
    @weights[-1] || 0
  end

  # ランダムに一つ選択する
  def chose_index_randomly
    value = @rand_proc && @rand_proc.call(sum_of_weights) || rand(sum_of_weights)
    @index_to_process = Utility::Array.upper_bound(value, @weights) || -1
  end
  
  def on_node_init
    return if @weights.empty?
    chose_index_randomly
  end
  
  def on_node_process
    # 選ばれた子を実行する
    if child = children[@index_to_process]
      child.node_process
    else
      Status::FAILURE
    end
  end

  def load_status(resuming_context, path)
    super
    chose_index_randomly if running?
  end

end
