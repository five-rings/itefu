=begin
  RGSS3やそのデフォルト実装で使用する文字列の特殊記号
=end
module Itefu::Rgss3::Definition::MessageFormat
  FONT_SIZE_SCALE  = 8    # 文字列を大きく/小さくするサイズの単位
  SHORT_WAIT_FRAME = 15   # 文字表示を少し待つフレーム数
  LONG_WAIT_FRAME  = 60   # 文字表示を長めに待つフレーム数

  NEW_LINE        = "\n"    # 改行
  CRLF            = "\r\n"  # エディタの改行文字
  COMMAND_PREFIX  = "\\"    # コマンドのプリフィックス
  ESCAPED_PREFIX  = "\\\\"  # エスケープ済みのプリフィックス文字

  # 制御文字の識別子
  module Command
    COLOR           = 'C'     # 色を変更する
    VARIABLE        = 'V'     # 変数と置き換える
    ACTOR_NAME      = 'N'     # アクターの名前と置き換える
    MEMBER_NAME     = 'P'     # パーティメンバーの名前と置き換える
    ICON            = 'I'     # アイコンを表示する
    TO_BIGGER       = '{'     # フォントサイズを大きくする
    TO_SMALLER      = '}'     # フォントサイズを小さくする
    WAIT_FOR_INPUT  = '!'     # 入力があるまで待機する
    AUTO_FEED       = '^'     # 文章表示後、自動で次の文章に進む
    WAIT_SHORT_TIME = '.'     # 短い間、文字の表示を待つ
    WAIT_LONG_TIME  = '|'     # 長い間、文字の表示を待つ
    SKIP            = '>'     # 残りの文字を一瞬で表示する
    CANCEL_TO_SKIP  = '<'     # SKIPを取り消す
    CURRENCY_UNIT   = 'G'     # 通貨に置き換えられる
    SHOW_BUDGET     = '$'     # 所持金ウィンドウを開く
  end

  # 添え字なども含めた制御文字のマッチングパターン
  module CommandPattern
    COLOR           = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::COLOR}\[(\d+)\]/o
    VARIABLE        = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::VARIABLE}\[(\d+)\]/o
    ACTOR_NAME      = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::ACTOR_NAME}\[(\d+)\]/o
    MEMBER_NAME     = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::MEMBER_NAME}\[(\d+)\]/o
    ICON            = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::ICON}\[(\d+)\]/o
    TO_BIGGER       = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::TO_BIGGER}(?:\[(\d+)\])?/o
    TO_SMALLER= /#{Regexp.escape(COMMAND_PREFIX)}#{Command::TO_SMALLER}(?:\[(\d+)\])?/o
    WAIT_FOR_INPUT  = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::WAIT_FOR_INPUT}/o
    AUTO_FEED       = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::AUTO_FEED}/o
    WAIT_SHORT_TIME = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::WAIT_SHORT_TIME}/o
    WAIT_LONG_TIME  = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::WAIT_LONG_TIME}/o
    SKIP            = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::SKIP}/o
    CANCEL_TO_SKIP  = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::CANCEL_TO_SKIP}/o
    CURRENCY_UNIT   = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::CURRENCY_UNIT}/o
    SHOW_BUDGET     = /#{Regexp.escape(COMMAND_PREFIX)}#{Command::SHOW_BUDGET}/o
  end

end
