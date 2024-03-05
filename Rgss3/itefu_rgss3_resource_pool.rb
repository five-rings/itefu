=begin
  リソースプール/事前に生成したリソースを使いまわすためのシステム
  @note Rgss3::Windowのように、生成が重く、同じサイズのものを何度も使いまわすようなものに使うと効果的
=end
module Itefu::Rgss3::Resource::Pool
  #　事前生成したリソース
  @@resources = {}

  # 事前にリソースを生成する
  def self.create(count, klass, *args)
    key = klass.resource_pool_key(*args)
    a = (@@resources[key] ||= [])
    count.times do
      a << klass.new_poolable(*args)
    end
  end
 
  # 事前生成したリソースを解放する
  # @note 他所で割り当てた分をすべて解放済みでなければ、これを呼んでも即解放されはしない 
  def self.remove_all_resources
    @@resources.each_value do |objects|
      objects.each(&:finalize)
      objects.clear
    end
  end

  # 解放図みのリソースを削除する
  def self.remove_disposed_resources
    @@resources.delete_if {|_, value|
      value.delete_if(&:disposed?)
      value.empty?
    }
  end

  # 事前生成済みのリソースから一つ割り当てる 
  # @note 割り当てられたオブジェクトは使い終わったらdisposeする
  # @note disposeすると自動的にwithdrawされる
  def self.assign(klass, *args)
    key = klass.resource_pool_key(*args)
    if (a = @@resources[key]) && (obj = a.pop)
      obj.ref_attach
      obj
    end
  end    
  
  # assingで割り当てたリソースを返却する
  # @note PooledResourceをmix-inされたオブジェクトは自動で返却するので、基本的には明示的に呼ぶ必要はない
  def self.withdraw(object)
    key = object.resource_pool_key
    @@resources[key] << object if @@resources.has_key?(key)
  end
 
  # 事前生成したリソースにmix-inされる 
  module PooledResource
    attr_accessor :resource_pool_args

    def dispose
      super
      if ref_count == 1
        reset_resource_properties(*resource_pool_args)
        Itefu::Rgss3::Resource::Pool.withdraw(self)
      end
    end
    
    def resource_pool_key
      self.class.resource_pool_key(*resource_pool_args)
    end
  end
  
  # 事前生成したいクラスにmix-inする
  module Poolable
    def resource_pool_key(*args)
      args
    end

    # 割り当てのためのnewを呼ぶ
    def new_poolable(*args)
      @new_poolable = true
      obj = new(*args).extend(PooledResource)
      @new_poolable = nil
      obj.resource_pool_args = args
      obj.reset_resource_properties(*args)
      obj
    end
    
    # 可能なときは事前生成したものから割り当てるようにする
    def new(*args)
      if @new_poolable
        # 事前生成のためのnew
        super
      else
        # 割り当てのためのnew
        if obj = Itefu::Rgss3::Resource::Pool.assign(self, *args)
          # 事前生成済みのオブジェクトを割り当てる
          obj
        else
          # 事前生成済みのものがないので新規に作成する
          super
        end
      end
    end
  end

end
