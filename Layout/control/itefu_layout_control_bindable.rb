=begin
  Layoutシステム/バインディング可能なアクセッサを定義できるようにする
=end
module Itefu::Layout::Control::Bindable
  BINDABLE_PREFIX = "bindable_"
  
  def self.included(obj)
    obj.extend Extension
  end
  
  # extendすることでattr_bindableを使用可能にする
  module Extension
    def attr_bindable(*args)
      args.each do |name|
        variable_name = :"@#{BINDABLE_PREFIX}#{name}"
        define_bindable_getter(name, variable_name)
        define_bindable_setter(name, variable_name)
     end
    end

  private

    def define_bindable_getter(name, variable_name)
      define_method(name) do
        BindingObject.unbox(instance_variable_get(variable_name))
      end
    end

    def define_bindable_setter(name, variable_name)
      # @note BindingObjectでないオブジェクトをボクシングしてポリモルフィズミックに処理するのが綺麗だが, BindingObjectの生成のために初期化の時間コストが大きくなってしまう.
      #       attr_bindableにする属性は多く, しかしほぼ大抵の場合ではbindingをしないので, 初期化時間を縮めることを優先して, setterで呼び分けることにしている.
      define_method(:"#{name}=") do |value|
        old_value = instance_variable_get(variable_name)
        if old_value.is_a?(BindingObject)
          return if old_value.update(value)
          # 以降の処理で、valueで上書きされるので、old_valueは無効にしておく
          old_value.invalidate
        end
        if value.is_a?(BindingObject)
          instance_variable_set(variable_name, value.bind(self, name))
          value.notify_changed(true)
        else
          instance_variable_set(variable_name, value)
          binding_value_changed(name, old_value) if value != old_value
        end
      end
    end
  end

  # Bindingを解除してnilを設定する
  def unbind(name)
    variable_name = :"@#{BINDABLE_PREFIX}#{name}"
    if instance_variable_defined?(variable_name)
      value = instance_variable_get(variable_name)
      instance_variable_set(variable_name, nil)
      value.invalidate if value.is_a?(BindingObject)
    end
  end

  # バインドされていたものを全て解除する
  def release_all_binding_objects
    # コントロールが 無効になった時点で observable_object を解放できるように参照を削除しておく
    # コントロールを finalize したのに、コントロールのインスタンスを握り続けるような状況を想定している
    instance_variables.each do |symbol|
      remove_instance_variable(symbol) if /^@#{BINDABLE_PREFIX}/o === symbol
    end
  end

  # @return [BindingObject] BindingObjectを生成する
  # @param [Object] 値を取得できなかったときに設定する値
  # @param [Proc] converter 取得した値を変換するProc
  # @param [Proc] block bindingするオブジェクトを呼び出すBlock
  def binding(default = nil, converter = nil, &block)
    ITEFU_DEBUG_ASSERT(block, "binding needs block", ArgumentError)
    BindingObject.new(self, default, converter, &block)
  end

  # attr_bindable で定義した変数が変更された場合に呼ばれる
  def binding_value_changed(name, old_value)
    raise Itefu::Layout::Definition::Exception::NotImplemented
  end


  # --------------------------------------------------
  #

  class BindingObject

    # @return [Object] BindingObjectであれば現在の値を取得して返す
    # @param [Object] value BindingObjectまたはその他の任意の値
    def self.unbox(value)
      case value
      when BindingObject
        value.unbox
      else
        value
      end
    end
    
    def valid?; invalid?.!; end                   # [Boolean] このBindingObjectが有効か
    def invalid?; @invalid || @owner.dead?; end   # [Boolean] このBindingObjectが無効か
    def invalidate; @invalid = true; end          # このBindingObjectを無効化する

    def initialize(owner, default, proc_converter, &proc_getter)
      @owner = owner
      @default = default
      @proc_converter = proc_converter if proc_converter
      @proc_to_get_value = proc_getter if proc_getter
      subscribe
    end

    # Bindingされている属性名を設定する
    # @param [String] attr_name 属性名
    # @return [BindingObject] レシーバー自身を返す
    def bind(owner, attr_name)
      ITEFU_DEBUG_ASSERT(@name.nil? && @owner.equal?(owner))
      @name = attr_name
      self
    end

    # 値の変更を通知する
    # @param [Boolean] force 値が変わっていなくても通知するか
    def notify_changed(force = false)
      old_value = @last_value
      if force
        unbox   # update last value
        @owner.binding_value_changed(@name, old_value)
      else
        if old_value != unbox
          @owner.binding_value_changed(@name, old_value)
        end
      end
    end
    
    # notify_changedをforce=trueで呼び出す
    def notify_changed_forcibly
      notify_changed(true)
    end

    # @return [Object] Bindingしている対象から実際の値を取り出す
    def unbox
      @last_value = unboxed_value
    end
    
    # Bindingしている内容を更新する
    # @return [BindingObject|NilClass] 更新できればレシーバー自身を返す
    def update(value)
      return self if self.equal?(value)
      return nil if value.is_a?(BindingObject)
      target = call_getter
      if target.is_a?(Itefu::Layout::Observable) && target.update(value)
        # 変更の通知はObservableから投げられるはずなので
        # こちらからは notify_changed しない
        self
      end
    end
    
    def inspect
      unboxed_value.inspect
    end

    def subscribe(target = call_getter)
      target.subscribe(self) if target.is_a?(Itefu::Layout::Observable)
      self
    end
    
  private
    def call_getter
      @owner.instance_eval(&@proc_to_get_value) if @proc_to_get_value
    rescue => e
      ITEFU_DEBUG_OUTPUT_NOTICE "callgetter #{e}"
      @default
    end
    
    # @return [Object] Bindingしている対象から実際の値を取り出す
    def unboxed_value
      value = call_getter
      value = value.is_a?(Itefu::Layout::Observable) ? value.value : value
      @proc_converter ? @owner.instance_exec(value, &@proc_converter) : value
    rescue
      @default
    end
  end
end
