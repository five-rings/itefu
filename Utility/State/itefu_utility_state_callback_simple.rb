=begin
  callback_nameを`state_モジュール名`に自動定義するState::Callbackの実装
=end
module Itefu::Utility::State::Callback::Simple
  def callback_name
    # on_state_module_event という形式でcontextのメソッドを呼び出すようにする
    snaked_name = Itefu::Utility::String.snake_case(self.name.gsub(/.*::(\w+)$/) { $1 })
    "state_#{snaked_name}"
  end
  def self.extended(obj); obj.extend Itefu::Utility::State::Callback; end
end
