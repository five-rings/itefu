=begin
  Contextのメソッドを呼び出すステート
  独自にcallback_nameを定義してメソッド名を指定する
=end
module Itefu::Utility::State::Callback
  include Itefu::Utility::State

  # 指定したイベントに対してcontextのメソッド on_callback_name_event を呼び出すようにする
  # callback_name が定義されていなければ、モジュール名を使用する
  def define_callback(*args)
    label = self.respond_to?(:callback_name) ? self.callback_name : self.name.gsub(/::/, "_")
    args.each do |event|
      raise ArgumentError, "unknown event '#{event}'" unless respond_to?(:"on_#{event}")
      # メソッド名を先に解決しておくことで呼び出し時のコストを軽減する
      eval(<<-"EOS", binding, Itefu::Utility::String.script_name(__FILE__), __LINE__)
        def self.on_#{event}(context, *args)
          context.on_#{label}_#{event}(*args)
        end
      EOS
    end
  end

end
