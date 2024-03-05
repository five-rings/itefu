=begin
  BehaviorTreeの実装で使用する共通の機能
=end
module Itefu::BehaviorTree::Common
  module Utility; include Itefu::Utility; end
  module Exception; include Itefu::Exception; end

  def debug_output(message)
    ITEFU_DEBUG_OUTPUT_NOTICE message
  end

  def show_exception(label, exception)
    ITEFU_DEBUG_OUTPUT_FATAL "#{label}: An Exception has occured."
#ifdef :ITEFU_LOGGING
    Itefu::Debug::Dump.show_exception(exception)
    Itefu::Debug::Dump.show_stacktrace(exception.backtrace)
#endif
  end

end

