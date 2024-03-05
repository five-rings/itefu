=begin
  デバッグ用ログ出力
=end
module Itefu::Debug::Log

  # ログ出力レベル
  module LogLevel
    NONE    = 0   # 何も表示しない
    FATAL   = 1   # 致命的なエラーに関するログまでを表示する
    ERROR   = 2   # 致命的でないエラーに関するログまでを表示する
    WARNING = 3   # 警告するログまでを表示する
    CAUTION = 4   # 注意するログまでを表示する
    NOTICE  = 5   # お知らせのログまでを表示する
    TEST    = 6   # 開発中のテスト用のログまでを表示する
    ALL     = 7   # 全てのログを表示する
  end
  @@log_level = LogLevel::ALL

class << self 

  # @return [IO] ログの出力先
  def default_out
    $stderr
  end

  # ログ出力レベルを設定する
  def log_level=(level)
    @@log_level = level
  end

  # デバッグログの出力
  # @param [Fixnum] ログレベル
  # @param [String] ログ内容
  # @note ログレベルはItefu::Debug::Log::LogLevelで指定する
  def output(level, message, out = nil)
    out ||= default_out
    out.puts message if level <= @@log_level
  rescue => e
    out.puts e
  end

  # システムの実行が不可能な致命的なエラーについてのログを出力する
  def fatal(message, out = nil); output(Itefu::Debug::Log::LogLevel::FATAL, "!!!fatal!!! #{message}", out); end

  # 何かに失敗した場合などに表示すべきログを出力する
  def error(message, out = nil); output(Itefu::Debug::Log::LogLevel::ERROR, "!error! #{message}", out); end

  # エラーではないが問題のある内容のログを出力する
  def warning(message, out = nil); output(Itefu::Debug::Log::LogLevel::WARNING, "*warning* #{message}", out); end

  # 即エラーにはつながらないが注意する必要のあるログを出力する
  def caution(message, out = nil); output(Itefu::Debug::Log::LogLevel::CAUTION, "+caution+ #{message}", out); end

  # デバッグ情報など不具合ではない確認用のメッセージを出力する
  def notice(message, out = nil); output(Itefu::Debug::Log::LogLevel::NOTICE, message, out); end

end
end
