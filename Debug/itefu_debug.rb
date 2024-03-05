=begin
  デバッグ関連の機能 
=end
module Itefu::Debug

  module RunLevel
    RELEASE   = 0   # 製品リリース相当 / デバッグ機能で停止させない
    TESTPLAY  = 1   # テストプレイ用 / デバッグ機能は使うが停止はせずログのみ出す
    DEBUG     = 2   # バグチェック用 / 停止させる
  end

  @@run_level = $itefu_default_runlevel || RunLevel::RELEASE
  @@paused = false

class << self

  def run_level=(level)
    @@run_level = level
  end
  
  # @return [Boolean] ポーズ中か
  def paused?
    @@paused
  end
  
  # ポーズする
  def pause
    @@paused = true
  end
  
  # 再開する
  def resume
    @@paused = false
  end
  
  # Assertion
  # @return [Boolean] conditionの値
  # @param [String] file ファイル名
  # @param [Fixnum] line 行番号
  # @param [Boolean] exp 正であるべき条件式を設定する
  # @param [String] 通知用のメッセージ
  # @param [Class] 失敗時に送出する例外クラス
  def assert(file, line, exp, message = nil, exception_klass = Itefu::Exception::AssertionFailed)
    unless exp
      case @@run_level
      when RunLevel::TESTPLAY
        Itefu::Debug::Log.fatal("Assertion Failed: #{message}")
        Itefu::Debug::Log.fatal(" at #{Itefu::Utility::String.script_name(file)}:#{line} ")
      when RunLevel::DEBUG
        raise exception_klass, "#{message} at #{Itefu::Utility::String.script_name(file)}:#{line}"
      end
    end
    exp
  end

end
end
