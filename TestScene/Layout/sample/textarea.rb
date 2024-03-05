message = <<EOS
あいうえお\\.…\\.…\\.\\I[10]
これがその\\{あいうえお\\}だ\\$
あいうえおと表示するのだ\\!

　羅馬に往きしことある人は\\>\\C[1]ピアツツア\\C、\\C[1]バルベリイニ\\C\\<を知りたるべし。こは貝殼持てる\\C[2]トリイトン\\Cの神の像に造り做したる、美しき噴井ある、大なる廣こうぢの名なり。\\>貝殼よりは水湧き出でゝその高さ數尺に及べり。\\<\\|羅馬に往きしことなき人もかの廣こうぢのさまをば銅板畫にて見つることあらむ。
EOS
mes2 = <<EOS
 He withdrew his dying eyes from the old man, and fixed them on the woman and the child.
 "My little Pearl," said he, feebly and there was a sweet and gentle smile over his face, as of a spirit sinking into deep repose; nay, now that the burden was removed, it seemed almost as if he would be sportive with the child--"dear little Pearl, wilt thou kiss me now?  Thou wouldst not, yonder, in the forest!  But now thou wilt?"
EOS
index = 0

_(Window, 640, 480) {
  attribute width: 640, height: 480

_(TextArea) {
  extend Background
  attribute name: :message,
            text: message,
            background: Color.DarkSlateGrey,
            width: 320, height: Size::AUTO,
            vertical_alignment: Alignment::TOP,
            horizontal_alignment: Alignment::STRETCH,
            text_anime_frame: 2,
            margin: const_box(20, 160)
  add_callback(:message_decided) do
    $stderr.puts "DECIDED!"
    if index == 0
      index += 1
      self.text = mes2
    else
      pop_focus
    end
  end
  add_callback(:commanded_to_show_budget) do
    $stderr.puts "Show Budget"
  end
}

}

self.add_callback(:layouted) do
  view.push_focus(:message)
end

