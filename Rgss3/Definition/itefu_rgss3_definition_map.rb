=begin
=end
module Itefu::Rgss3::Definition::Map
  
  # ScrollTypeというよりLoopTypeな気がするがRGSSの定義に沿う
  module ScrollType
    FIX        = 0    # ループしない
    VERTICAL   = 1    # 縦方向にループする
    HORIZONTAL = 2    # 横方向にループする
    BOTH       = 3    # 両方向にループする
  
    # @return [Boolean] 縦方向にスクロールするか
    def self.loop_vertically?(scroll_type)
      (scroll_type & 0b1) != 0
    end
    
    # @return [Boolean] 横方向にループするか
    def self.loop_horizontally?(scroll_type)
      (scroll_type & 0b10) != 0
    end
  end

end