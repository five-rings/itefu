
maihime = <<EOS
あ……いう）えおか\\C[1]きくけ、こ\\Cさしすせそ1023たちつてと
　石炭をば早や積み果てつ。中等室の卓のほ）とりはいと靜にて、の光の晴れがましきも徒なり。今宵は夜毎にこゝに集ひ來る仲間も「ホテル」に宿りて、舟に殘れるは余一人のみなれば。
単
（（行頭禁則が二つ並ぶ場合のテスト文章））
単語の行頭禁則のテストの文章だ！！！！！！！
！\\K！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！\\C！

とても長い文章をこういう風にlonglonglonglonglongverylongtextmessageを表示するとこうなる
あまりに短い場合longlonglonglonglongverylongtextmessageという風に無理に広げない。
EOS


_(Window, 640, 480) {
  attribute width: 640, height: 480
  _(Grid) {
    add_row_separator 70, 500
    
    _(Text) {
      extend Background
      attribute text: "あ……いう）\\}えおか\\C[1]きき\\I[1]\\I[2]くけ、、\\Cこさ\\{しす\\\\せaそ",
                grid_row: 0, grid_col: 0,
                background: Color.Black,
                vertical_alignment: Alignment::CENTER,
                horizontal_alignment: Alignment::CENTER,
                fill_padding: true,
                hanging: true,
                width: 1.0, height: 1.0,
                padding: const_box(5,13,2,11)
    }

    _(Text) {
      extend Background
      attribute text: maihime,
                horizontal_alignment: Alignment::LEFT,
                word_to_fill: 6,
                grid_row: 1, grid_col: 0,
                width: 1.0, height: 1.0,
                background: Color.Black,
                text_word_space: 0,
                margin: const_box(5)
    }

    _(Text) {
      extend Background
      attribute text: "あい\\I[1]うえお\nかきくけこ\\I[33]",
                grid_row: 2, grid_col: 0,
                background: Color.Black,
                text_line_space: 10,
                margin: const_box(100,2,2,2)
    }

  }
}

