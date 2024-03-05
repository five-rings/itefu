=begin
  作成したリソースを管理しまとめて解放する
=end
# @note 終了時にまとめてfinalizeを呼ぶ対象を管理する
module Itefu::Resource::Container

  def initialize(*args)
    @contained_resources = []
    super
  end
  
  module ContainedResource
    attr_accessor :resource_index
  end

  # リソースを生成する
  # @return [Object] 生成したリソース  
  def create_resource(klass, *args, &block)
    resource = klass.new(*args, &block)
    resource.extend ContainedResource
    resource.resource_index = @contained_resources.size
    @contained_resources << resource
    resource
  end
  
  # リソースを複数生成する
  # @return [Array<Object>] 生成したリソース
  def create_resources(count, klass, *args, &block)
    i = @contained_resources.size
    resources = i.upto(i + count - 1).map {|c|
      klass.new(*args, &block).tap {|res|
        res.extend ContainedResource
        res.resource_index = c
      }
    }
    @contained_resources.concat(resources)
    resources
  end
  
  # 生成住みのリソースを破棄して代わりに新しいリソースを生成する
  def change_resource(old_res, klass, *args, &block)
    return unless ContainedResource === old_res
    i = old_res.resource_index
    return unless old_res.equal? @contained_resources[i]
    new_res = klass.new(*args, &block)
    new_res.extend ContainedResource
    new_res.resource_index = i
    @contained_resources[i] = new_res
    old_res.finalize
    new_res
  end
  
  # 生成したリソース全てのfinalizeを呼ぶ
  def finalize_all_resources
    @contained_resources.each(&:finalize)
    @contained_resources.clear
  end

end
