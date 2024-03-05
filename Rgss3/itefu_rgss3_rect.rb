=begin
  Rect関連の独自実装
=end
module Itefu::Rgss3::Rect
  # 一時変数として使用できる
  TEMP = Rect.new
  TEMPs = Hash.new {|h, k| h[k] = Rect.new }
end
