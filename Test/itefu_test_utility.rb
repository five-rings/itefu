=begin
  Utilityのテストコード
=end
class Itefu::Test::Utility < Itefu::UnitTest::TestCase

  def test_math_clamp
    assert_equal(10, Itefu::Utility::Math.clamp(-0.5, 100, 10))
    assert_equal(-0.5, Itefu::Utility::Math.clamp(-0.5, 100, -100))
    assert_equal(100, Itefu::Utility::Math.clamp(-0.5, 100, 1000))
  end
  
  def test_math_wrap
    assert_equal(10, Itefu::Utility::Math.wrap(-0.5, 100, 10))
    assert_equal(100, Itefu::Utility::Math.wrap(-0.5, 100, -100))
    assert_equal(-0.5, Itefu::Utility::Math.wrap(-0.5, 100, 1000))
  end
  
  def test_math_loop
    assert_equal(3, Itefu::Utility::Math.loop(3, 5, 3))
    assert_equal(4, Itefu::Utility::Math.loop(3, 5, 4))
    assert_equal(5, Itefu::Utility::Math.loop(3, 5, 5))
    assert_equal(4, Itefu::Utility::Math.loop(3, 5, 1))
    assert_equal(4, Itefu::Utility::Math.loop(3, 5, 10))
    assert_equal(5, Itefu::Utility::Math.loop(3, 5, -1))
  end

  def test_math_loop_size
    assert_equal(3, Itefu::Utility::Math.loop_size(5, 3))
    assert_equal(4, Itefu::Utility::Math.loop_size(5, 4))
    assert_equal(0, Itefu::Utility::Math.loop_size(5, 5))
    assert_equal(2, Itefu::Utility::Math.loop_size(5, 12))
    assert_equal(2, Itefu::Utility::Math.loop_size(5, -3))
  end

  def test_math_min
    assert_equal(10, Itefu::Utility::Math.min(10, 10.1))
    assert_equal(0.9, Itefu::Utility::Math.min(10, 0.9))
    assert_equal(-1.5, Itefu::Utility::Math.min(10, -1.5))
  end

  def test_math_max
    assert_equal(10.1, Itefu::Utility::Math.max(10, 10.1))
    assert_equal(10, Itefu::Utility::Math.max(10, 0.9))
    assert_equal(10, Itefu::Utility::Math.max(10, -1.5))
  end

  def test_math_rand_in
    100.times {
      min = rand(100)
      max = min + rand(20)
      num = Itefu::Utility::Math.rand_in(min, max)
      assert(min <= num)
      assert(num <= max)
    }
  end

  def test_math_bezier3
    resolution = 10
    delta = 2**-(resolution+1)
    100.times {
      p1 = rand(0)
      p2 = rand(0)
      t = rand(0)
      p = Itefu::Utility::Math.bezier3(0, p1, p2, 1, t)
      t2 = Itefu::Utility::Math.solve_bezier3_for_t(p1, p2, p, resolution)
      assert_in_delta(t, t2, delta, "bezier3(0, #{p1}, #{p2}, 1, #{t}) = #{p}, solved for t = #{t2}")
    }
  end

  def test_math_normal_rand
    r = Itefu::Utility::Math::NormalRandom.new
    s = 10000.times.map { r.rand }
    assert_in_delta(0.0, s.inject(0, &:+)/10000, 0.05)
    assert_in_delta(1.0**2, s.inject(0) {|m, v| m + (0 - v)**2 } / 10000, 0.05)

    # specifying average and variance
    r = Itefu::Utility::Math::NormalRandom.new(10, 20)
    s = 10000.times.map { r.rand }
    assert_in_delta(10, s.inject(0, &:+)/10000, 10 * 0.5)
    assert_in_delta(20**2, s.inject(0) {|m, v| m + (10 - v)**2 } / 10000, 400*0.05)

    r = Itefu::Utility::Math::NormalRandom.new(10, 20)
    s = 10000.times.map { r.rand(0.5, 0.2) } # specifying average and variance when call rand
    assert_in_delta(0.5, s.inject(0, &:+)/10000, 0.5 * 0.05)
    assert_in_delta(0.2**2, s.inject(0) {|m, v| m + (0.5 - v)**2 } / 10000, 0.05)
  end
  
  def test_array_binary_seach
    array = 10.times.map(&:to_i)
    assert_equal(4, Itefu::Utility::Array.binary_search(4, array))
    assert_equal(2, Itefu::Utility::Array.binary_search(4, array) {|v| v * 2 })

    assert_nil(Itefu::Utility::Array.binary_search(10, array))
    assert_equal(9, Itefu::Utility::Array.binary_search(10, array, true))

    assert_nil(Itefu::Utility::Array.binary_search(-1, array))
    assert_equal(0, Itefu::Utility::Array.binary_search(-1, array, true))
  end
  
  def test_array_upper_bound
    array = 10.times.map(&:to_i)
    assert_equal(5, Itefu::Utility::Array.upper_bound(4, array))
    assert_equal(3, Itefu::Utility::Array.upper_bound(4, array) {|v| v * 2 })

    assert_equal(10, Itefu::Utility::Array.upper_bound(10, array))
    assert_equal(0, Itefu::Utility::Array.upper_bound(-1, array))
    assert_equal(10, Itefu::Utility::Array.upper_bound(10, array) {|v| v / 2 })
    assert_equal(0, Itefu::Utility::Array.upper_bound(-1, array) {|v| v  / 2 })
  end
  
  def test_array_lower_bound
    array = 10.times.map(&:to_i)
    assert_equal(4, Itefu::Utility::Array.lower_bound(4, array))
    assert_equal(2, Itefu::Utility::Array.lower_bound(4, array) {|v| v * 2})

    assert_equal(10, Itefu::Utility::Array.lower_bound(10, array)  {|v| v  / 2 })
    assert_equal(0, Itefu::Utility::Array.lower_bound(-1, array)  {|v| v  / 2 })
  end
  
  def test_array_insert_to_sorted_array
    array = 5.times.map {|v| (v + 1) * 2 }
    assert_equal([1,2,4,6,8,10], Itefu::Utility::Array.insert_to_sorted_array(1, array.clone))
    assert_equal([2,4,5,6,8,10], Itefu::Utility::Array.insert_to_sorted_array(5, array.clone))
    assert_equal([2,4,6,8,10,11], Itefu::Utility::Array.insert_to_sorted_array(11, array.clone))

    assert_equal(["a", "bb", "ccc", "dddd"], Itefu::Utility::Array.insert_to_sorted_array("ccc", ["a", "bb", "dddd"]) {|v| v.size })
  end

  def test_array_weighted_randomly_select
    cs = 5.times.map {|v| "x" * rand(10) }

    ret = Itefu::Utility::Array.weighted_randomly_select(cs) {|v| v.size }
    assert_instance_of(Fixnum, ret)

    ret = Itefu::Utility::Array.weighted_randomly_select(cs, nil, 3) {|v| v.size }
    assert_instance_of(Array, ret)
    assert_equal(3, ret.size)
  end
  
  def test_function_recursive
    assert_equal(55, Itefu::Utility::Function.recursive(10) {|f,n| n > 1 ? n + f.(n-1) : 1 })
    assert_equal(55, Itefu::Utility::Function.recursive {|f,n| n > 1 ? n + f.(n-1) : 1 }.call(10))
  end
  
  def test_time
    assert_equal(1000, Itefu::Utility::Time.frame_to_millisecond(60))
    assert_equal(60, Itefu::Utility::Time.millisecond_to_frame(1000))
    assert_equal("00:00:12", Itefu::Utility::Time.second_to_hms(12))
    assert_equal("00:02:03", Itefu::Utility::Time.second_to_hms(123))
    assert_equal("01:04:30", Itefu::Utility::Time.second_to_hms(3870))
    assert_equal("123:02:03", Itefu::Utility::Time.second_to_hms(3600*123+123))
    assert_equal("1:4:2", Itefu::Utility::Time.second_to_hms(3842, "%d:%d:%d"))
  end
  
  def test_string_note_command
    assert(Itefu::Utility::String.note_command(:command, ":command"))
    assert(Itefu::Utility::String.note_command(:command, ":nomean").!)
    assert(Itefu::Utility::String.note_command(:command, "").!)
    assert_equal("string", Itefu::Utility::String.note_command(:value=, ":value=string"))
    assert_equal(123, Itefu::Utility::String.note_command_i(:value=, ":value=123"))
    assert_equal(0.5, Itefu::Utility::String.note_command_f(:value=, ":value=0.5"))
    assert_equal(:symbol, Itefu::Utility::String.note_command_s(:value=, ":value=symbol"))
    assert_nil(Itefu::Utility::String.note_command(:value=, ":value="))
    assert_nil(Itefu::Utility::String.note_command(:value=, ":value"))
    assert_nil(Itefu::Utility::String.note_command_i(:value=, ":value="))
    assert_nil(Itefu::Utility::String.note_command_f(:value=, ":value="))
    assert_nil(Itefu::Utility::String.note_command_s(:value=, ":value="))
    assert_nil(Itefu::Utility::String.note_command_i(:value=, ":value"))
    assert_nil(Itefu::Utility::String.note_command_f(:value=, ":value"))
    assert_nil(Itefu::Utility::String.note_command_s(:value=, ":value"))
  end
  
  def test_string_parse_note_command
    assert_nil(Itefu::Utility::String.parse_note_command(""))
    assert_equal([:command, nil], Itefu::Utility::String.parse_note_command(":command"))
    assert_equal([:value, ""], Itefu::Utility::String.parse_note_command(":value="))
    assert_equal([:value, "string"], Itefu::Utility::String.parse_note_command(":value=string"))
  end

  def test_string_to_number
    assert_kind_of(Integer, Itefu::Utility::String.to_number("10"))
    assert_kind_of(Float, Itefu::Utility::String.to_number("10.0"))
    assert_kind_of(String, Itefu::Utility::String.to_number("10a"))
  end
  
  def test_string_snake_case
    assert_equal("snake_case", Itefu::Utility::String.snake_case("snake_case"))
    assert_equal("camel_case", Itefu::Utility::String.snake_case("camelCase"))
    assert_equal("upper_camel_case", Itefu::Utility::String.snake_case("UpperCamelCase"))
  end
  
  def test_string_camel_case
    assert_equal("snakeCase", Itefu::Utility::String.camel_case("snake_case"))
    assert_equal("camelCase", Itefu::Utility::String.camel_case("camelCase"))
    assert_equal("upperCamelCase", Itefu::Utility::String.camel_case("UpperCamelCase"))
  end
  
  def test_string_upper_camel_case
    assert_equal("SnakeCase", Itefu::Utility::String.upper_camel_case("snake_case"))
    assert_equal("CamelCase", Itefu::Utility::String.upper_camel_case("camelCase"))
    assert_equal("UpperCamelCase", Itefu::Utility::String.upper_camel_case("UpperCamelCase"))
  end
  
  def test_string_remove_namespace
    assert_equal("Class", Itefu::Utility::String.remove_namespace("Name::Space::Class"))
    assert_equal("Class", Itefu::Utility::String.remove_namespace("Class"))
    assert_equal("", Itefu::Utility::String.remove_namespace(""))
  end
  
  def test_string_script_name
    assert_equal("itefu/test/itefu_test_utility.rb", Itefu::Utility::String.script_name(__FILE__))
  end
  
  def test_string_commaization
    assert_equal("1,234,567,890", Itefu::Utility::String.number_with_comma(1234567890))
    assert_equal("-123,456,789", Itefu::Utility::String.number_with_comma(-123456789))
    assert_equal("12,345.6789", Itefu::Utility::String.number_with_comma(12345.6789))
    assert_equal("12_3456_7890", Itefu::Utility::String.number_with_comma(1234567890, "_", 4))
    
    
    assert_equal(1234567890, Itefu::Utility::String.number_without_comma("1,234,567,890"))
    assert_equal(12345.6789, Itefu::Utility::String.number_without_comma("12,345.6789"))
    assert_equal(12345678, Itefu::Utility::String.number_without_comma("12_345_678", "_"))
  end
  
  def test_string_shrink
    assert_equal("abcde…", Itefu::Utility::String.shrink("abcdefg", 6))
    assert_equal("abcde*", Itefu::Utility::String.shrink("abcdefg", 6, "*"))
    assert_equal("abcdef", Itefu::Utility::String.shrink("abcdefg", 6, nil))
    assert_equal("abcdefg", Itefu::Utility::String.shrink("abcdefg", 7))
    assert_equal("...", Itefu::Utility::String.shrink("abcdefg", 2, "..."))
  end

  def test_digit
    assert_equal(1, Itefu::Utility::String.digit(0))
    assert_equal(1, Itefu::Utility::String.digit(9))
    assert_equal(2, Itefu::Utility::String.digit(10))
    assert_equal(2, Itefu::Utility::String.digit(99))
    assert_equal(3, Itefu::Utility::String.digit(100))
    assert_equal(3, Itefu::Utility::String.digit(999))
    assert_equal(1, Itefu::Utility::String.digit(0x0, 16))
    assert_equal(1, Itefu::Utility::String.digit(0xf, 16))
    assert_equal(2, Itefu::Utility::String.digit(0x10, 16))
    assert_equal(2, Itefu::Utility::String.digit(0xff, 16))
    assert_equal(3, Itefu::Utility::String.digit(0x100, 16))
    assert_equal(3, Itefu::Utility::String.digit(0xfff, 16))
  end

  def test_letter_number
    assert_equal("", Itefu::Utility::String.letter_number(0))
    assert_equal("a", Itefu::Utility::String.letter_number(1))
    assert_equal("z", Itefu::Utility::String.letter_number(26))
    assert_equal("aa", Itefu::Utility::String.letter_number(27))
    assert_equal("A", Itefu::Utility::String.letter_number(1, 'A'))
    assert_equal("Z", Itefu::Utility::String.letter_number(26,'A'))
    assert_equal("AA", Itefu::Utility::String.letter_number(27,'A'))
    assert_equal("A", Itefu::Utility::String.letter_number(1, 'A', 10))
    assert_equal("J", Itefu::Utility::String.letter_number(10, 'A', 10))
    assert_equal("AA", Itefu::Utility::String.letter_number(11, 'A', 10))
    assert_equal("", Itefu::Utility::String.letter_number(0, nil, 1))
    assert_equal("a", Itefu::Utility::String.letter_number(1, nil, 1))
    assert_equal("aaaaaaaaaa", Itefu::Utility::String.letter_number(10, nil, 1))
  end

  def test_number_with_leading
    assert_equal("00023", Itefu::Utility::String.number_with_leading(23, 5, 10))
    assert_equal("12", Itefu::Utility::String.number_with_leading(12, 0, 10))
    assert_equal("12", Itefu::Utility::String.number_with_leading(12, 1, 10))
    assert_equal("12", Itefu::Utility::String.number_with_leading(12, 2, 10))
    assert_equal("012", Itefu::Utility::String.number_with_leading(12, 3, 10))
    assert_equal("c", Itefu::Utility::String.number_with_leading(12, 0, 16))
    assert_equal("c", Itefu::Utility::String.number_with_leading(12, 1, 16))
    assert_equal("0c", Itefu::Utility::String.number_with_leading(12, 2, 16))
  end

  def test_dicimal_part
    assert_equal(".0", Itefu::Utility::String.dicimal_part(0))
    assert_equal(".0", Itefu::Utility::String.dicimal_part(0.0))
    assert_equal("0", Itefu::Utility::String.dicimal_part(0.0, 0))
    assert_equal("", Itefu::Utility::String.dicimal_part(0.0, 1))
    assert_equal(".345", Itefu::Utility::String.dicimal_part(12.345))
    assert_equal("345", Itefu::Utility::String.dicimal_part(12.345, 0))
    assert_equal("45", Itefu::Utility::String.dicimal_part(12.345, 1))
  end
  
  module TestEnum
    Itefu::Utility::Module.declare_enumration(self, [
      :FIRST, :SECOND, :THIRD,
    ], 1)
  end
  
  def test_module_declare_enumration
    assert_equal(1, TestEnum::FIRST)
    assert_equal(2, TestEnum::SECOND)
    assert_equal(3, TestEnum::THIRD)
  end
  
  module TestEnum2
    Itefu::Utility::Module.declare_enumration(self, [
      :FIRST, :SECOND, :THIRD,
    ], 1) {|index| index * 2 }
  end
  
  def test_module_const_values
    assert_equal([1, 2, 3], Itefu::Utility::Module.const_values(TestEnum))
    assert_equal([2, 4, 6], Itefu::Utility::Module.const_values(TestEnum2))
    
    consts = []
    Itefu::Utility::Module.const_values(TestEnum) do |value, name|
      consts.push [value, name]
    end
    assert_equal([
      [1, :FIRST],
      [2, :SECOND],
      [3, :THIRD],
    ], consts)
  end
  
  module TestConst
  end

  def test_module_define_const
    Itefu::Utility::Module.define_const(TestConst, :TEST) do
      10
    end
    assert_equal(10, TestConst::TEST)
    
    # to not evaluate block
    Itefu::Utility::Module.define_const(TestConst, :TEST) do
      raise Itefu::UnitTest::Assertion::Failed
    end
  end
  
  class TestForLazyDeclare
    attr_reader :id
    def initialize(id = nil)
      @id = id
      @@count += 1
    end

    def self.reset_count; @@count = 0; end
    def self.count; @@count; end
  end
  
  module Lazy
    Itefu::Utility::Module.declare_lazy_constant(self, :LazyTest, TestForLazyDeclare)
  end
  
  def test_lazy_declaration
    TestForLazyDeclare.reset_count
    assert_includes(Lazy.instance_methods, :LazyTest)
    assert_equal(0, TestForLazyDeclare.count)
    Lazy.extend Lazy
    assert(Lazy.LazyTest.frozen?)
    assert_equal(1, TestForLazyDeclare.count)
    Lazy.LazyTest
    assert_equal(1, TestForLazyDeclare.count)
  end

  module Lazy2
    def self.declare_test(name, id)
      Itefu::Utility::Module.declare_lazy_constant(self, name, TestForLazyDeclare, id)
    end
    declare_test(:First, 10)
    declare_test(:Second, 20)
    declare_test(:Third, 30)
  end

  def test_lazy_declaration2
    TestForLazyDeclare.reset_count
    assert_equal(0, TestForLazyDeclare.count)
    assert_includes(Lazy2.instance_methods, :First)
    assert_includes(Lazy2.instance_methods, :Second)
    assert_includes(Lazy2.instance_methods, :Third)

    Lazy2.extend Lazy2
    assert_equal(10, Lazy2.First.id)
    assert_equal(1, TestForLazyDeclare.count)
    Lazy2.First
    assert_equal(1, TestForLazyDeclare.count)

    assert_equal(20, Lazy2.Second.id)
    assert_equal(2, TestForLazyDeclare.count)
    Lazy2.Second
    assert_equal(2, TestForLazyDeclare.count)

    assert_equal(30, Lazy2.Third.id)
    assert_equal(3, TestForLazyDeclare.count)
    Lazy2.Third
    assert_equal(3, TestForLazyDeclare.count)
  end
  
  class Expected; end
  class NotExpected; end
  module ExpectFor
    extend Itefu::Utility::Module.expect_for(Expected)
  end
  module Unexpected; end
  class UnexpectFor
    include Itefu::Utility::Module.unexpect_for(Unexpected)
    extend Itefu::Utility::Module.unexpect_for(Unexpected)
  end
  
  def test_expect_for
    # valid - the object is a kind of Expected
    Expected.new.extend ExpectFor
    
    assert_raises(Itefu::Exception::AssertionFailed) do
      NotExpected.new.extend ExpectFor
    end
    
    # valid - the klass inherits Expected
    Class.new(Expected) do |c|
      include ExpectFor
    end
    
    assert_raises(Itefu::Exception::AssertionFailed) do
      Class.new do |c|
        include ExpectFor
      end
    end
  end

  def test_unexpect_for
    assert_raises(Itefu::Exception::AssertionFailed) do
      UnexpectFor.new.extend Unexpected
    end

    assert_raises(Itefu::Exception::AssertionFailed) do
      Class.new(UnexpectFor) do |c|
        include Unexpected
      end
    end
  end
  
  class Callback
    include Itefu::Utility::Callback
    attr_accessor :data
    def test(cb)
      @data = :test
    end
  end
  
  def test_callback
    cb = Callback.new
    # add a callback
    cb.add_callback(:method, cb.method(:test))
    cb.add_callback(:block) {|c| c.data = :block }
    assert(cb.has_callback?(:method))
    assert(cb.has_callback?(:block))
    # execute
    cb.execute_callback(:method)
    assert_equal(:test, cb.data)
    cb.execute_callback(:block)
    assert_equal(:block, cb.data)
    # remove
    cb.remove_callback(:method, cb.method(:test))
    assert(cb.has_callback?(:method).!)
    cb.execute_callback(:method)
    assert_not_equal(:test, cb.data)
    # add callbacks
    cb.add_callback(:both, cb.method(:test)) {|c| c.data = [c.data, :block] }
    cb.execute_callback(:both)
    assert_equal([:test, :block], cb.data)
    # clear
    cb.clear_callbacks(:both)
    assert(cb.has_callback?(:both).!)
    cb.add_callback(:both, cb.method(:test)) {|c| c.data = [c.data, :block] }
    assert(cb.has_callback?(:both))
    assert(cb.has_callback?(:block))
    cb.clear_callbacks
    assert(cb.has_callback?(:both).!)
    assert(cb.has_callback?(:block).!)
    
  end

end
