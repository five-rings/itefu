=begin
  デバッグ出力へのダンプを行う
=end
module Itefu::Debug::Dump
class << self
  
  # 空白をログに出力する
  # @param [IO] out 出力先
  def show_blank(out = nil)
    Itefu::Debug::Log.notice("", out)
  end

  # 日時をログに出力する
  # @param [Time] time 出力する日時
  # @param [IO] out 出力先
  def show_timestamp(time, out = nil)
    Itefu::Debug::Log.notice "# timestamp", out
    Itefu::Debug::Log.notice time.strftime("%Y/%m/%d-%H:%M:%S"), out
  end
  
  # 例外情報をログに出力する
  # @param [Exception] exception 出力する例外情報
  # @param [IO] out 出力先
  def show_exception(exception, out = nil)
    Itefu::Debug::Log.notice "# exception information", out
    Itefu::Debug::Log.notice exception.inspect, out
    Itefu::Debug::Log.notice exception.to_s, out
  end

  # スタックトレースをログに出力する
  # @note Exception.backtraceや callerを渡して使う
  # @param [Array<String>] callstack 呼び出し情報の配列
  # @param [IO] out 出力先
  def show_stacktrace(callstack, out = nil)
    Itefu::Debug::Log.notice "# stacktrace", out
    callstack.each do |info|
      Itefu::Debug::Log.notice Itefu::Utility::String.script_name(info), out
    end
  end
  
  # システムの情報をログに出力する
  # @param [System::Base] system 出力したいシステムクラスのインスタンス
  # @param [IO] out 出力先
  def show_system(system, out = nil)
    system.dump_log(out)
  end

  # リソースの情報をログに出力する
  # @param [Rgss3::Resource] resource 出力したいリソースクラスのインスタンス
  # @param [IO] out 出力先
  def show_resource(resource, out = nil)
    resource.dump_log(out)
  end

end
end
