=begin
  RGSS3やそのデフォルト実装で使用している色関連の定数
=end
module Itefu::Rgss3::Definition::Color
  extend Itefu::Color::Declaration
  extend Itefu::Rgss3::Definition::Color

  declare_color(:Whitening, 0xff, 0xff, 0xff, 0xff)
  declare_color(:Collapsing, 0xff, 0x80, 0x80, 0x80)
  declare_color(:BossCollapsing, 0xff, 0xff, 0xff, 0xff)
end
