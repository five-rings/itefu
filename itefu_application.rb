=begin
  フレームワークのメインループのインターフェイス
=end
# @note このクラスは継承して使用する
class Itefu::Application
#ifdef :ITEFU_LOGGING
  USE_INSPECTION = false
#endif
  attr_reader :system_manager
  @@rgss_reset = false
  @@snapshot = nil

  # アプリケーションを実行する  
  def self.run
    app = $itefu_application = new
    app.send(:run)
  end
  
  # @return [Boolean] RGSSResetでリセットされた状態か
  # @note System::Manager#shutdownから呼ばれるSystem::Base#finalizeの中で参照する用
  def self.rgss_reset?; @@rgss_reset; end

  # @return [Boolean] 処理中か
  # @note これがfalseを返すとゲームが終了する
  def running?; true; end

  # システムクラスを追加する
  # @param [Class] system_klass 追加したいクラスの型 (System::Baseを継承したもの)
  def add_system(system_klass, *args, &block)
    @system_manager.register(system_klass, *args, &block)
  end
  
  # システムクラスのインスタンスを得る
  # @return [System::Base] システムクラスのインスタンス
  # @param [Class] klass インスタンスを得たいクラスの型
  def system(klass)
    @system_manager.system(klass)
  end
  
  # 画面のスナップショットを作成する
  def self.create_snapshot
    @@snapshot.dispose if @@snapshot
    @@snapshot = Graphics.snap_to_bitmap.extend Itefu::Rgss3::Resource
  end
  
  # 画面のスナップショットを破棄する
  def self.remove_snapshot
    if @@snapshot
      @@snapshot.dispose
      @@snapshot = nil
    end
  end
  
  # @return [Bitmap] 最後に作成したスナップショット
  # @note 返り値がItefu::Rgss3::BitmapではなくBitmapであることに注意
  def self.snapshot
    @@snapshot
  end

private
  # --------------------------------------------------
  # 継承先で必要に応じてover-rideする

  def on_initialize; end      # 初期化前に一度だけ呼ばれる
  def on_initialized; end     # 初期化後に一度だけ呼ばれる
  def on_finalize; end        # 終了前に一度だけ呼ばれる
  def on_finalized; end       # 終了後に一度だけ呼ばれる
  def on_pre_running; end     # メイン処理に入る前に呼ばれる, RGSSResetでリセットされた場合に再度呼ばれることがある
  def on_running; end         # メイン処理, 毎フレームの最初に一度呼ばれる
  def on_aborted(e); end      # 例外終了した場合に呼ばれる   @param [Exception] e 例外情報
  def on_logging(io); end     # 例外終了しログを出力する際に呼ばれる @param [IO] io 出力先

  # @return [String] 例外終了する際に表示される文章
  def error_message(logfile)
    "何らかの理由でアプリケーションを動かし続けられなくなったので、ゲームを終了します。\n\n開発者向けの情報: #{logfile}"
  end
  
  # @return [String] クラッシュログを出力する先のファイル名
  def logfile_name(time)
    time.strftime("crash%Y%m%d%H%M%S.txt")
  end

  # --------------------------------------------------
  # 以下、内部実装

  def run
#ifdef :ITEFU_MASTER
    logging_run { impl_main }
#else
    debug_run { impl_main }
#endif
  end

  def impl_main
    impl_initialize
    rgss_main do
      impl_reset
      impl_running
    end
    impl_finalize
  end
  
  def impl_initialize
    on_initialize
    @system_manager = Itefu::System::Manager.new(self)
    on_initialized
  end
  
  # RGSSResetでリセットされたときは、@system_managerにシステムのインスタンスがある
  # システムのfinalizeを呼んでから終了するが、その際にリセット用の処理を行えるように@@rgss_resetを立てる
  def impl_reset
    @@rgss_reset = true
    @system_manager.shutdown
    @@rgss_reset = false
    Itefu::Resource::Loader.release_cache
    Itefu::Rgss3::Bitmap.clear_empty
#ifdef :ITEFU_DEVELOP
    Itefu::Rgss3::Resource.remove_disposed_resources
#endif
    Itefu::Rgss3::Resource::Pool.remove_disposed_resources
    self.class.remove_snapshot
   end
  
  # main loop
  def impl_running
    on_pre_running
    while running?
      on_running
      @system_manager.update
#ifdef :ITEFU_DEVELOP
      if Itefu::Debug.paused?
        Itefu::Win32.sleep(Itefu::Utility::Time.frame_to_millisecond(1))
        next
      end
#endif
      rgss3_graphics_update
    end
  end

  def rgss3_graphics_update
    Graphics.update
  end
  
  def impl_finalize
    on_finalize
    @system_manager.shutdown
    Itefu::Rgss3::Resource::Pool.remove_all_resources
    Itefu::Rgss3::Bitmap.clear_empty
    Itefu::Resource::Loader.release_cache
    self.class.remove_snapshot
    on_finalized
  end
  
  def logging_run
    yield
  rescue RGSSReset
    raise 
  rescue Exception => e
    on_aborted(e)
    logfile = logfile_name(Time.now)
    File.open(logfile, "w") {|f|
      f.puts e.backtrace
      f.puts e.inspect
      on_logging(f)
    }
    message = error_message(logfile)
    msgbox(message) if message
    exit
  end

#ifdef :ITEFU_LOGGING
  def debug_run
    yield
  rescue RGSSReset
    raise 
  rescue Exception => e
    on_aborted(e)
    output_debug_informations(e)
    inspection($stdin, $stderr) if USE_INSPECTION
  end

  def output_debug_informations(exception)
    system_manager.systems.each_value do |system|
      Itefu::Debug::Dump.show_system(system)
    end if system_manager
    Itefu::Debug::Dump.show_blank
    Itefu::Debug::Dump.show_stacktrace(exception.backtrace.reverse)
    Itefu::Debug::Dump.show_blank
    Itefu::Debug::Dump.show_exception(exception)
    msgbox("An exception has occurred.", "\n", exception.inspect)
  end 

  def inspection(input, output)
    output.puts "# inspection"
    output.puts "  !! Type  q  to quit"
    loop do
      command = $stdin.gets
      break if command.chomp == "q"
      begin
        eval(command)
      rescue Exception => e
        output.puts "# An exception has occured"
        output.puts e.message
      end
    end
  end
#endif

end
