=begin
  Inputのテストコード
=end
class Itefu::Test::Input < Itefu::UnitTest::TestCase

  class DummyInputStatus < Itefu::Input::Status::Base
    attr_accessor :rawkeystates
    attr_optional_value :position_x
    attr_optional_value :position_y

    def initialize
      super
      @rawkeystates = {}
      @optional_values[:position_x] = 10
      @optional_values[:position_y] = 123
    end

    def press_key?(key_code)
      @rawkeystates[key_code].!.!
    end

  end

  class DummyInputManager < Itefu::Input::Manager
  end
  
  def test_input_key_state
    rawkeystates = {}
    status = DummyInputStatus.new
    status.rawkeystates = rawkeystates
    status.repeat_wait = 10000
    status.setup([:key])

    # None
    status.update
    assert(status.triggered?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.pressed?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.released?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.triggered?(:button).!)
    assert(status.pressed?(:button).!)
    assert(status.released?(:button).!)
    
    # Triggered
    rawkeystates[:key] = true
    status.update
    assert(status.triggered?(:key), status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.pressed?(:key), status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.released?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.triggered?(:button).!)
    assert(status.pressed?(:button).!)
    assert(status.released?(:button).!)

    # Pressing
    status.update
    assert(status.triggered?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.pressed?(:key), status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.released?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.triggered?(:button).!)
    assert(status.pressed?(:button).!)
    assert(status.released?(:button).!)

    # Released
    rawkeystates[:key] = false
    status.update
    assert(status.triggered?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.pressed?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.released?(:key), status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.triggered?(:button).!)
    assert(status.pressed?(:button).!)
    assert(status.released?(:button).!)

    # None again
    status.update
    assert(status.triggered?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.pressed?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.released?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
    assert(status.triggered?(:button).!)
    assert(status.pressed?(:button).!)
    assert(status.released?(:button).!)
  end

  def test_input_key_state_repeat
    rawkeystates = {}
    status = DummyInputStatus.new
    status.rawkeystates = rawkeystates
    status.repeat_wait = 0.01
    status.setup([:key])

    # None
    status.update
    assert(status.repeated?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })

    # Triggered
    rawkeystates[:key] = true
    status.update
    assert(status.repeated?(:key), status.instance_eval { "Key State is #{@states[:key].inspect}" })

    # Not The Time to Be Repeated Yet
    status.update
    assert(status.repeated?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })

    # Repeated    
    sleep(status.repeat_wait*2)
    status.update
    assert(status.repeated?(:key), status.instance_eval { "Key State is #{@states[:key].inspect}, time: #{Time.now - @repeats[:key]}" })

    # Released
    sleep(status.repeat_wait*2)
    rawkeystates[:key] = false
    status.update
    assert(status.repeated?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })

    # None again
    sleep(status.repeat_wait*2)
    status.update
    assert(status.repeated?(:key).!, status.instance_eval { "Key State is #{@states[:key].inspect}" })
  end

  def test_input_semantic_key
    rawkeystates = {}
    semantics = Itefu::Input::Semantics.new(DummyInputStatus).instance_eval {
      define(:decide, :key, :button)
      define(:cancel, :trigger, :switch)
      self
    }

    system_manager = Itefu::System::Manager.new(self)
    manager = system_manager.register(DummyInputManager)
    manager.add_semantics(:dummy, semantics)
    status = manager.find_status(DummyInputStatus)
    assert(status.nil?.!)
    status.rawkeystates = rawkeystates

    # はじめは何も押していない
    manager.update
    assert(manager.triggered?(:decide).!)
    assert(manager.triggered?(:cancel).!)

    # decideのキーのうち一つが押される
    rawkeystates[:key] = true
    manager.update
    assert(manager.triggered?(:decide))
    assert(manager.triggered?(:cancel).!)

    # decideのキーのうち別の一つが押される
    rawkeystates[:key] = false
    rawkeystates[:button] = true
    manager.update
    assert(manager.triggered?(:decide))
    assert(manager.triggered?(:cancel).!)
    
    # decideのキーすべてが離される
    rawkeystates[:button] = false
    manager.update
    assert(manager.triggered?(:decide).!)
    assert(manager.triggered?(:cancel).!)

    # decideにひもづけられたキーの削除を試す
    rawkeystates[:button] = true
    manager.update
    assert(manager.triggered?(:decide))
    semantics.undefine(:decide, :button)
    assert(manager.triggered?(:decide).!)
    assert(manager.triggered?(:cancel).!)

    system_manager.shutdown
  end
  
  def test_input_position
    system_manager = Itefu::System::Manager.new(self)
    manager = system_manager.register(DummyInputManager)
    manager.add_status(DummyInputStatus)

    manager.update
    assert_equal(10, manager.position_x)
    assert_equal(123, manager.position_y)
    
    system_manager.shutdown
  end
  
  class DummyManagerForCommander
    attr_accessor :triggered
    attr_accessor :pressed
    def initialize
      @triggered = {}
      @pressed = {}
    end
    def triggered?(key)
      @triggered[key]
    end
    def triggered_any?
      @triggered.each_value.any? {|v| v }
    end
    def pressed?(key)
      @pressed[key] || triggered?(key)
    end
    def released_any?
      triggered_any?.!
    end
  end
  
  CommanderState = Itefu::Input::Commander::State

  def test_input_command
    manager = DummyManagerForCommander.new
    commander = Itefu::Input::Commander.new
    context = commander.instance_variable_get(:@context)
    c1 = commander.new_command
    c2 = Itefu::Input::Command.new
    commander.add_command(c2)
    
    c1.add_stroke(:key, :triggered?)
    c2.add_stroke(:shift, :triggered?)
    c2.add_stroke(:key, :triggered?, :key2)
    
    commander.update(manager)
    assert_equal(CommanderState::FirstStroke, commander.state)
    
    manager.triggered[:key] = true
    commander.update(manager)
    manager.triggered[:key] = false
    assert_equal(CommanderState::Executing, commander.state)

    commander.update(manager)
    assert_equal(CommanderState::FirstStroke, commander.state)

    manager.triggered[:shift] = true
    commander.update(manager)
    assert_equal(CommanderState::WaitForNextStroke, commander.state)

    manager.pressed[:key] = true
    commander.update(manager)
    assert_equal(CommanderState::AdditionalStroke, commander.state)

    manager.triggered[:shift] = false
    manager.pressed[:key] = false
    commander.update(manager)
    assert_equal(CommanderState::FirstStroke, commander.state)

    manager.triggered[:shift] = true
    commander.update(manager)
    manager.triggered[:key] = true
    commander.update(manager)
    assert_equal(CommanderState::AdditionalStroke, commander.state)
    assert_equal(context.stroke_count, 1)
    manager.pressed[:key2] = true
    commander.update(manager)
    assert_equal(CommanderState::Executing, commander.state)
  end
  
end
