=begin
  RGSS3の解放が必要なものを自動解放リソースにする
=end
module Itefu::Rgss3::Resource
  include Itefu::Resource::ReferenceCounter
  alias :ref_detach_org :ref_detach

  def initialize(*args, &block)
    super
  end

  def self.extended(object)
#ifdef :ITEFU_DEVELOP
    object.extend ModuleExtension
    object.setup_class_extension(object.class)
#endif
    object.initialize_variables
  end

  def initialize_variables(*args)
    super
#ifdef :ITEFU_DEVELOP
    # 生成されたインスタンスの情報を統計用に保存する
    @debug_id = self.class.class_variable_get(:@@debug_counter)
    self.class.class_variable_set(:@@debug_counter, @debug_id + 1)
    resources = self.class.class_variable_get(:@@debug_resources)
    resources[@debug_id] = {
      :instance => self,
      :args => args, 
      :caller => caller,
    }
#endif
  end
  
  # 何らかの理由で既に生成したリソースを再度初期化したい場合に呼ぶ
  def reset_resource_properties(*args); end

  # このリソースへの参照をやめる際に呼ぶ
  def ref_detach
    dispose
  end

  # 参照カウンタを下げ、誰からも参照されていなければ解放する
  def dispose
    ref_detach_org do
      impl_dispose
      # 実際の解放を行う
      super
    end unless disposed?  # RGSSResetで外部からdisposeされていることもあるのでチェックしてから解放する
  end
  
  def impl_dispose
#ifdef :ITEFU_DEVELOP
    # 統計情報からも削除する
    res = self.class.class_variable_get(:@@debug_resources)
    res.delete(@debug_id)
#endif
  end

  # ブロックを実行してから自身を解放する
  # @yield 任意のブロック, このリソース自身が引数として渡される
  # @return [Rgss3::Resource] 自身を返す
  def auto_release
    yield(self)
    ref_detach
    self
  end

  # Itefu::Resource::ReferenceCounter.swapのResource版  
  # @param (see #Itefu::Resource::ReferenceCounter.swap)
  # @return (see #Itefu::Resource::ReferenceCounter.swap)
  def self.swap(old_value, new_value)
    new_value.ref_attach  if new_value && new_value.disposed?.!
    # Window.contentsのためにref_detachでなくdisposeを呼ぶ
    # rgss3::resourceにとってはdispose=ref_detachになる
    old_value.dispose     if old_value && old_value.disposed?.!
    new_value
  end

  # self.swapを呼び出す
  # @note レシーバーがnilの可能性がある場合はself.swapを使うこと
  # @param [ReferenceCounter] new_value
  # @return [ReferenceCounter] new_valueを返す
  def swap(new_value)
    Itefu::Rgss3::Resource.swap(self, new_value)
  end


#ifdef :ITEFU_DEVELOP
  @@resource_classes = []
  def self.resource_classes; @@resource_classes; end
  
  # Itefu::Rgss3::Resourceをmix-inしている全てのクラスの解放済みリソースを除去する
  # @note RGSSResetで外部からdisposeされたリソースの除去するために使用する
  def self.remove_disposed_resources
    resource_classes.each(&:remove_disposed_resources)
  end

  # Itefu::Rgss3::Resourceをmix-inするモージュールを拡張する
  module ModuleExtension
    def included(klass)
      if klass.is_a?(Class)
        # 生成されたインスタンス数を計測するための変数を用意する
        setup_class_extension(klass)
      else
        klass.extend ModuleExtension
      end
    end
    def setup_class_extension(klass)
      # 生成されたインスタンス数を計測するための変数を用意する
      klass.class_variable_set(:@@debug_counter, 0) unless klass.class_variable_defined?(:@@debug_counter)
      klass.class_variable_set(:@@debug_resources, {}) unless klass.class_variable_defined?(:@@debug_resources)
      klass.extend ClassExtension
      Itefu::Rgss3::Resource.resource_classes << klass unless Itefu::Rgss3::Resource.resource_classes.include? klass
    end
  end
  extend ModuleExtension

  # Itefu::Rgss3::Resourceをmix-inするクラスを拡張する
  module ClassExtension
    # 確保済みのリソースを出力する
    def dump_log(out, start_index = 0, count = nil)
      Itefu::Debug::Log.notice self, out
      out_with_indent = IndentOutput.new(out, 2)

      resources = class_variable_get(:@@debug_resources)
      resources.each do |key, value|
        Itefu::Debug::Log.notice "#{key} #{value[:args]} count: #{value[:instance].ref_count} disposed: #{value[:instance].disposed?}", out
        c = count || value[:caller].size
        if c > 0
          Itefu::Debug::Dump.show_stacktrace(value[:caller][start_index, c], out_with_indent)
          Itefu::Debug::Log.notice "", out
        end
      end
      Itefu::Debug::Log.notice "total: #{resources.size}", out
    end
    
    # disposeされているリソースを除去する
    # @note RGSSResetで外部からdisposeされたリソースの除去するために使用する
    def remove_disposed_resources
      class_variable_get(:@@debug_resources).delete_if do |key, value|
        value[:instance].disposed?
      end
    end

    # 出力内容をインデントさせるためのラッパー
    class IndentOutput
      def initialize(out, depth)
        @out = out
        @indent = " " * depth
      end
      def puts(*args)
        @out.puts(*(args.map {|s| @indent + s }))
      end
    end
  end
#endif

end
