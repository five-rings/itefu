=begin
  Exceptions
=end
module Itefu::Exception

  # Assertの条件を満たさなかった
  class AssertionFailed < StandardError; end

  # 実装されていないメソッドを呼び出した
  class NotImplemented < StandardError; end

  # 非サポートの機能を呼び出した
  class NotSupported < StandardError; end

  # 到達しないはずの行を実行した
  class Unreachable < StandardError; end

end

