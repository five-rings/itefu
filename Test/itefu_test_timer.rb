=begin
  Timerのテストコード
=end
class Itefu::Test::Timer < Itefu::UnitTest::TestCase

  def setup
    @manager = Itefu::Timer::Manager.new(nil)
  end
  
  def teardown
    @manager.finalize
    @manager = nil
  end
  
  def sleep
    Graphics.update
  end

  def test_real_timer
    timer = @manager.create_instance(Itefu::Timer::Real)
    t1 = timer.elapsed
    sleep
    t2 = timer.elapsed
    assert(t1 < t2, "Expected #{t1} < #{t2}")
    
    timer.reset
    assert_equal(0, timer.elapsed)

    # ポーズのテスト
    sleep
    timer.pause
    t1 = timer.elapsed
    sleep
    t2 = timer.elapsed
    timer.resume
    sleep
    t3 = timer.elapsed
    assert_equal(t1, t2)
    assert(t2 < t3, "Expected #{t2} < #{t3}")
  end
  
  def test_performance_timer
    timer = @manager.create_instance(Itefu::Timer::PerformanceCounter)
    t1 = timer.elapsed
    sleep
    t2 = timer.elapsed
    assert(t1 < t2, "Expected #{t1} < #{t2}")
    
    timer.reset
    assert_in_delta(0, timer.elapsed, 0.001)

    # ポーズのテスト
    sleep
    timer.pause
    t1 = timer.elapsed
    sleep
    t2 = timer.elapsed
    timer.resume
    sleep
    t3 = timer.elapsed
    assert_equal(t1, t2)
    assert(t2 < t3, "Expected #{t2} < #{t3}")
  end
  
  def test_frame_timer
    @manager.update
    timer = @manager.create_instance(Itefu::Timer::Frame)
    t1 = timer.elapsed
    sleep
    t2 = timer.elapsed
    # managerのupdateがかかるまで(同一フレーム内なら)同じ値になる
    assert_equal(t1, t2)

    timer.reset
    assert_equal(0, timer.elapsed)

    t1 = timer.elapsed
    sleep
    @manager.update
    t2 = timer.elapsed
    # updateがはさまれば値が進む
    assert(t1 < t2, "Expected #{t1} < #{t2}")

    # ポーズのテスト
    sleep
    timer.pause
    t1 = timer.elapsed
    sleep
    @manager.update
    t2 = timer.elapsed
    timer.resume
    sleep
    @manager.update
    t3 = timer.elapsed
    assert_equal(t1, t2)
    assert(t2 < t3, "Expected #{t2} < #{t3}")
  end
  
  def test_time_in_frame
    @manager.update
    ft1 = @manager.frame_time
    sleep
    ft2 = @manager.frame_time
    assert_equal(ft1, ft2)
    @manager.update
    ft3 = @manager.frame_time
    assert_not_equal(ft1, ft3)
    sleep
    t1 = @manager.frame_time_elapsed
    assert(17, t1, 1) # 1frame分 = 16.66..->17になるはずだが誤差も考慮する
  end
  
end
