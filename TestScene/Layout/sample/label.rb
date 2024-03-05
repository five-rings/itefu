=begin
  Labelのテスト
=end

_(Label) {
  extend Background
  attribute text: "テストラベル",
            margin: box(50),
            padding: box(10),
            background: Color.White,
            horizontal_alignment: Alignment::CENTER,
            vertical_alignment: Alignment::CENTER,
            font_color: Color.Red,
            font_out_color: Color.Blue,
            font_size: 30
}

