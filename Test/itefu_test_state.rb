=begin
  Stateのテストコード
=end
class Itefu::Test::State < Itefu::UnitTest::TestCase

  class TestContext
    include Itefu::Utility::State::Context
    def data; state_work[:data]; end
  end

  class TestState
    extend Itefu::Utility::State

    def self.on_attach(context)
      context.state_work[:data] = :attached
    end
  
    def self.on_update(context)
      context.state_work[:data] = :updated
    end
  
    def self.on_draw(context)
      context.state_work[:data] = :drawn
    end

    def self.on_detach(context)
      context.state_work[:data] = :detached
    end
  end
  
  def test_state
    state = TestContext.new
    assert_nil(state.data)
    
    state.change_state(TestState)
    assert_equal(TestState, state.state)
    assert_equal(:attached, state.data)
    
    state.update_state
    assert_equal(:updated, state.data)

    state.draw_state
    assert_equal(:drawn, state.data)
    
    state.clear_state
    assert_equal(:detached, state.data)
    assert_equal(Itefu::Utility::State::DoNothing, state.state)
  end
  
  
  class TestSimpleCallback
    include Itefu::Utility::State::Context
    def data; state_work[:data]; end

    module First
      extend Itefu::Utility::State::Callback::Simple
      define_callback :attach, :detach
    end

    module Second
      extend Itefu::Utility::State::Callback::Simple
      define_callback :update, :draw, :detach
    end
    
    def on_state_first_attach
      state_work[:data] = :attached1
    end

    def on_state_first_detach
      state_work[:data] = :detached1
    end

    def on_state_second_update
      state_work[:data] = :updated2
    end

    def on_state_second_draw
      state_work[:data] = :drawn2
    end

    def on_state_second_detach
      state_work[:data] = :detached2
    end
  end
    
  def test_simple_callback
    state = TestSimpleCallback.new
    assert_nil(state.data)

    state.change_state(TestSimpleCallback::First)
    assert_equal(TestSimpleCallback::First, state.state)
    assert_equal(:attached1, state.data)

    state.update_state
    assert_equal(:attached1, state.data)

    state.draw_state
    assert_equal(:attached1, state.data)

    state.change_state(TestSimpleCallback::Second)
    assert_equal(TestSimpleCallback::Second, state.state)
    assert_equal(:detached1, state.data)

    state.update_state
    assert_equal(:updated2, state.data)

    state.draw_state
    assert_equal(:drawn2, state.data)
    
    state.clear_state
    assert_equal(:detached2, state.data)
    assert_equal(Itefu::Utility::State::DoNothing, state.state)
  end
  
end
