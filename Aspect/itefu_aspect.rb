=begin
  簡易的なAOP風の処理を記述するための最低限の機能

Usage:
  module MyAspect
    extend Itefu::Aspect

    # hook an instance method
    # optional: args, block
    advice SomeClass, :method_name do |caller, *args, &block|
      # some processes
      returned_value = caller.()  # must be called!
      # some processes
    end
    
    # hook a class method
    advice class_method SomeClass, :method_name do |c, *a, &b|
      r = c.()  # must be called!
    end
  end
=end
module Itefu::Aspect

  # DSL風にadviceを設定する
  def advice(*args, &block)
    case args.size
    when 1
      raise ArgumentError unless Array === args[0]
      target, method = args[0]
    when 2
      target, method = args
    else
      raise ArgumentError
    end
    Itefu::Aspect.add_advice(target, method, &block)
  end

  # クラスメソッドにadviceを設定するためのhelper
  def class_method(klass, method)
    return klass.singleton_class, method
  end
  
  # 使用する必要はないが対称性をはかるために提供する
  def instance_method(klass, method)
    return klass, method
  end

  # @note Ad-hocなadviceの設定に直接使用してもよい
  def self.add_advice(target, method, &block)
    case target
    when Module
      target.extend Extension
    else
      raise Itefu::Exception::NotSupported
    end
    target.itefu_aspect_add_advice(method, &block)
  end

  # adviceを設定されるクラスに拡張する
  module Extension

    def itefu_aspect_add_advice(method, &block)
      @itefu_aspect ||= {}
      unless @itefu_aspect.has_key?(method)
        original = itefu_aspect_alias(method)
        itefu_aspect_hook(method)
        @itefu_aspect[method] = [original]
      end
      @itefu_aspect[method] << block
    end

    def itefu_aspect_alias(method)
      original = :"aspect_org_#{method}"
      alias_method original, method
      original
    end

    def itefu_aspect_hook(method)
      this = self
      define_method(method) do |*args, &block|
        this.itefu_aspect_call(self, method, *args, &block)
      end
    end
    
    def itefu_aspect_call(this, method, *args, &block)
      Caller.new(this, @itefu_aspect[method], *args, &block).call
    end
  end

  # adviceを呼ぶためのhelper
  class Caller
    attr_reader :index
    attr_reader :this

    def initialize(this, advices, *args, &block)
      @this = this
      @advices = advices
      @args = args
      @block = block
      @index = advices.size - 1
    end

    def call
      index = @index
      @index -= 1
      if index > 0
        # 追加したアドバイスを呼ぶ
        @advices[index].call(self, *@args, &@block)
      elsif index == 0
        # 元のメソッドを呼ぶ
        @result = @this.send(@advices[index], *@args, &@block)
      end
      @result
    end
  end
end

