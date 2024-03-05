=begin
  Aspectのテストコード
=end
class Itefu::Test::Aspect < Itefu::UnitTest::TestCase

  class Mock
    attr_accessor :done
    def do_something(v)
      self.done = v
      :done2
    end
    def self.do_something(v)
      @@done = v
      :done1
    end
    def self.done
      @@done
    end
  end
  
  module MyAspect
    extend Itefu::Aspect
    @result = []
    
    advice Mock, :do_something do |c|
      @result.push c.()
    end
    
    advice instance_method Mock, :do_something do |c|
      @result.push c.()
    end
    
    advice class_method Mock, :do_something do |c|
      @result.push c.()
    end
    
    def self.result; @result; end
  end

  def test_aspect
    assert_equal(:done1, Mock.do_something(:test1))
    assert_equal(:test1, Mock.done)
    assert_equal([:done1], MyAspect.result)

    mock = Mock.new
    assert_equal(:done2, mock.do_something(:test2))
    assert_equal(:test2, mock.done)
    assert_equal([:done1, :done2, :done2], MyAspect.result)
  end
  
end
