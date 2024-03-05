=begin
  参照カウンタ  
=end
module Itefu::Resource::ReferenceCounter
  attr_reader :ref_count

  def initialize(*args)
    super
    initialize_variables(*args)
  end
  
  def self.extended(object)
    object.initialize_variables
  end
  
  def initialize_variables(*args)
    @ref_count = 1
  end
  
  # ref_detachの別名
  def finalize
    ref_detach
  end

  # このリソースを参照する際に呼ぶ
  def ref_attach(count = 1)
    @ref_count += count
  end

  # このリソースへの参照をやめる際に呼ぶ
  # @yield 参照カウンタが0になったときに呼ぶ解放処理
  def ref_detach(count = 1)
    @ref_count -= count
    if ref_releaseable?
      yield if block_given?
    end
  end

  # @return [Boolean] リソースを解放可能か
  def ref_releaseable?
    self.ref_count <= 0
  end

  # 保持する値を入れ替える際に使用する
  # @note old_value == new_value の際にカウントが0にならないように, new_valueのカウントを上げてからold_valueのカウントを下げる
  # @param [ReferenceCounter] old_value
  # @param [ReferenceCounter] new_value
  # @return [ReferenceCounter] new_valueを返す
  def self.swap(old_value, new_value)
    new_value.ref_attach if new_value
    old_value.ref_detach if old_value
    new_value
  end
  
  # self.swapを呼び出す
  # @note レシーバーがnilの可能性がある場合はself.swapを使うこと
  # @param [ReferenceCounter] new_value
  # @return [ReferenceCounter] new_valueを返す
  def swap(new_value)
    Itefu::Resource::ReferenceCounter.swap(self, new_value)
  end

end
