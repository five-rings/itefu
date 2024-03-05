=begin
  リソースを裏読みするシステム
  @note 別スレッドでロードしてもブロックするので、メインスレッドで毎フレームの空き時間を使ってロードする
=end
class Itefu::BackgroundLoader::Manager < Itefu::System::Base
  # [Fixnum] フレーム内の時間が、この値になるまでは処理をする(ミリ秒)
  # @warning 大きな値にすると処理落ちしやすくなるので注意すること
  attr_accessor :time_to_finish_processing

  # デフォルト値
  DEFAULT_TIME_TO_FINISH_PROCESSING = 10

  # @return [Boolean] 読み込む予定のデータが存在するか
  def queued?; @queue.empty?.!; end
  
  # Bitmapの読み込みをリクエストする
  # @param [Itefu::Resource::Loader] loader 実際に読み込を行うローダ
  # @param [String] filename ファイル名
  # @param [Fixnum] hue 色相
  def queue_to_load_bitmap(loader, filename, hue = nil)
    queue(loader, :load_bitmap_resource, filename, hue)
  end

  # rvdata2の読み込みをリクエストする
  # @param [Itefu::Resource::Loader] loader 実際に読み込を行うローダ
  # @param [String] filename ファイル名
  def queue_to_load_rvdata2(loader, filename)
    queue(loader, :load_rvdata2_resource, filename)
  end

private

  def on_initialize
    @queue = []
    @time_to_finish_processing = DEFAULT_TIME_TO_FINISH_PROCESSING
#ifdef :ITEFU_DEVELOP
    if performance = manager.system(Itefu::Debug::Performance::Manager)
      performance.add_counter(:backgroundloader, Itefu::Color.Green)
    end
#endif
  end

  def on_finalize
    # 要求されたがロードしなかったものはそのまま捨てる
    @queue.clear
  end

  def on_update
#ifdef :ITEFU_DEVELOP
    if performance = manager.system(Itefu::Debug::Performance::Manager)
      performance.counter(:backgroundloader).measure { process_queue }
    else
#endif
      process_queue
#ifdef :ITEFU_DEVELOP
    end
#endif
  end

  # 読み込みをリクエストする
  def queue(*args)
    @queue << args
  end

 # 読み込みのリクエストを処理する
  def process_queue
    timer = @manager.system(Itefu::Timer::Manager)
    unless timer
      ITEFU_DEBUG_OUTPUT_ERROR "BackgroundLoader needs Timer::Manager"
      return
    end

    # 処理可能な間、少しずつロードしていく
#ifdef :ITEFU_DEBUG
    mpf = Itefu::Utility::Time.frame_to_millisecond(1)
    elapsed = timer.frame_time_elapsed 
    while elapsed < @time_to_finish_processing
      loader, command, *args = @queue.shift
      break unless loader && command
      loader.send(command, *args)
      elapsed = timer.frame_time_elapsed
      if elapsed > mpf
        ITEFU_DEBUG_OUTPUT_WARNING "BackgroundLoader: frame dropped (#{elapsed} > #{mpf}) to load #{args.inspect}"
      end
    end
#else
    while timer.frame_time_elapsed < @time_to_finish_processing
      loader, command, *args = @queue.shift
      break unless loader && command
      loader.send(command, *args)
    end
#endif
  end
  
end
