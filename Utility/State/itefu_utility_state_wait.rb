=begin
  指定フレーム待ってから次のステートに遷移する
=end
module Itefu::Utility::State::Wait
  extend Itefu::Utility::State

  def self.on_attach(context, count, next_state, *args)
    context.state_work[:count] = count
    context.state_work[:next] = next_state
    context.state_work[:args] = args
  end

  def self.on_update(context, *args)
    if (context.state_work[:count] -= 1) <= 0
      context.change_state(context.state_work[:next], *context.state_work[:args])
    end
  end

  def self.on_detach(context, *args)
    context.state_work[:next] = nil
  end

end
