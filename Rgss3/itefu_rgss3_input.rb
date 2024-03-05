=begin
  RGSS3のInputの拡張
=end
module Itefu::Rgss3::Input

  # @note RGSS3ではボタンをシンボルでも識別できるが、イベントなどでは数値で指定される
  module Code
    DOWN  = 2
    LEFT  = 4
    RIGHT = 6
    UP    = 8
    A     = 11
    B     = 12
    C     = 13
    X     = 14
    Y     = 15
    Z     = 16
    L     = 17
    R     = 18
  end

end
