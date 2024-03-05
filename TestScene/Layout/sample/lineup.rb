=begin
  Lineupのテスト
=end

_(Decorator) {
  attribute height: Size::AUTO,
            width: Size::AUTO

_(Sprite, 0, 0) {
  attribute width: Size::AUTO, height: Size::AUTO,
            margin: box(120, 120)
  
_(Lineup) {
  extend Scrollable
#  extend SpriteTarget

  attribute width: Size::AUTO, height: Size::AUTO,
            max_width: 16,
            max_height: 120,
            horizontal_alignment: Alignment::LEFT,
            vertical_alignment: Alignment::TOP,
            scroll_y: 32,
            orientation: Orientation::VERTICAL

  10.times {|i|
    _(Icon) { attribute icon_index: i+1 }
  }
} if true

}
}

