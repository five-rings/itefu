=begin
  Layoutシステム/MVVMのViewModelを実装するための定義
=end
module Itefu::Layout::ViewModel
  OBSERVABLE_PREFIX = "observable_"

  def self.included(obj)
    # 自動的にObservableObjectを使用するアクセッサを定義できるようにする
    obj.extend Extension
  end

  module Extension
    def attr_observable(*args)
      args.each do |name|
        variable_name = :"@#{OBSERVABLE_PREFIX}#{name}"
        define_observable_getter(name, variable_name)
        define_observable_setter(name, variable_name)
      end
    end

  private
    def define_observable_getter(name, variable_name)
      define_method(name) do
        instance_variable_get(variable_name)
      end
    end

    def define_observable_setter(name, variable_name)
       define_method(:"#{name}=") do |value|
        old_value = instance_variable_get(variable_name)
        if old_value
          old_value.value = value
        else
          instance_variable_set(variable_name, Itefu::Layout::ObservableObject.new(value))
        end
      end
    end
  end

end