=begin
  ユニットテストの条件の記述を行うためのモジュール
=end
module Itefu::UnitTest::Assertion
  attr_reader :assertion_count    # [Fixnum] assertを読んだ回数
  class Failed < Exception; end   # assertに失敗した際に投げられる
  class Skipped < Exception; end  # テストをスキップする際に投げる

  def initialize(*args)
    super
    reset_assertion_count
  end

  # assertを読んだ回数をリセットする
  def reset_assertion_count
    @assertion_count = 0
  end

  # expが真であることを表明する
  # @param [Boolean] exp 評価する値
  # @param [Array<String>] messages 失敗時に表示するメッセージ
  def assert(exp, *messages)
    @assertion_count += 1
    unless exp
      raise Itefu::UnitTest::Assertion::Failed, messages.compact.join(", ")
    end
    true
  end

  # ブロックが真を返すことを表明する
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_block(message = nil)
    assert(yield, message, "Expected block to return true")
  end

  # オブジェクトが空であることを表明する
  # @param [Object] object 空であるはずのオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_empty(object, message = nil)
    assert(object.empty?, message, "Expected #{object.inspect} to be empty")
  end

  # オブジェクトが空でないことを表明する
  # @param [Object] object 空でないはずのオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_not_empty(object, message = nil)
    assert(object.empty?.!, message, "Expected #{object.inspect} not to be empty")
  end

  # 現在値が期待値と等しいことを表明する
  # @param [Object] expected 期待値
  # @param [Object] actual 現在値
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_equal(expected, actual, message = nil)
    assert(expected == actual, message, "Expected: #{expected}, Actual: #{actual}")
  end

  # 現在値が期待値と等しくないことを表明する
  # @param [Object] expected 期待値
  # @param [Object] actual 現在値
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_not_equal(expected, actual, message = nil)
    assert(expected != actual, message, "Expected: #{expected}, Actual: #{actual}")
  end

  # 現在値と期待値との差が許容範囲内であることを表明する
  # @param [Integer] expected 期待値
  # @param [Integer] actual 現在値
  # @param [Integer] delta 許容値
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_in_delta(expected, actual, delta = 0.001, message = nil)
    n = (expected - actual).abs
    assert(n <= delta, message, "Expected: #{expected} - #{actual} (#{n}) < #{delta}")
  end

  # 現在値と期待値との相対誤差が許容範囲内であることを表明する
  # @param [Integer] expected 期待値
  # @param [Integer] actual 現在値
  # @param [Integer] epsilon 相対誤差の許容値
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_in_epsilon(expected, actual, epsilon = 0.001, message = nil)
    assert_in_delta(expected, actual, [expected, actual].min * epsilon, message)
  end

  # コレクションにオブジェクトが含まれることを表明する
  # @param [Array<Object>] collection コレクション
  # @param [Object] object 含まれるはずのオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_includes(collection, object, message = nil)
    assert(collection.include?(object), message, "Expected #{collection.inspect} to include #{object.inspect}")
  end

  # オブジェクトが指定したクラスの直接のインスタンスであることを表明する
  # @param [Class] klass 確認するクラス
  # @param [Object] object 対象のオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_instance_of(klass, object, message = nil)
    assert(object.instance_of?(klass), message, "Expected #{object.inspect}(#{object.class}) to be an instance of #{klass}")
  end

  # オブジェクトが指定したクラスかそのサブクラスのインスタンスであることを表明する
  # @param [Class] klass 確認するクラス
  # @param [Object] object 対象のオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_kind_of(klass, object, message = nil)
    assert(object.kind_of?(klass), message, "Expected #{object.inspect}(#{object.class}) to be a kind of #{klass}")
  end

  # オブジェクトが指定した正規表現とマッチすることを表明する
  # @param [Regexp] regexp 確認する正規表現
  # @param [Object] object 対象のオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_match(regexp, object, message = nil)
    assert(regexp.match(object), message, "Expected #{regexp.inspect} to match #{object.inspect}")
  end

  # オブジェクトが指定した正規表現とマッチしないことを表明する
  # @param [Regexp] regexp 確認する正規表現
  # @param [Object] object 対象のオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_not_match(regexp, object, message = nil)
    assert(regexp.match(object).nil?, message, "Expected #{regexp.inspect} to match #{object.inspect}")
  end

  # オブジェクトがnilであることを表明する
  # @param [Object] object nilであるはずのオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_nil(object, message = nil)
    assert(object.nil?, message, "Expected #{object.inspect} to be nil")
  end
  
  # オブジェクトがnilでないことを表明する
  # @param [Object] object nilでないはずのオブジェクト
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_not_nil(object, message = nil)
    assert(object.nil?.!, message, "Expected #{object.inspect} not to be nil")
  end

  # 指定した式が真を返すことを表明する
  # @param [Object] lhs 左辺
  # @param [Object] operator 演算子
  # @param [Object] rhs 右辺
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_operator(lhs, operator, rhs, message = nil)
    assert(lhs.__send__(operator, rhs), message, "Expected #{lhs.inspect} #{operator} #{rhs.inspect} to be true")
  end

  # ブロックが例外を送出することを表明する
  # @param [Array<Exception>] args 送出される例外の候補
  def assert_raises(*args)
    exp = false
    begin
      yield
    rescue Itefu::UnitTest::Assertion::Skipped => e
      if args.include?(Itefu::UnitTest::Assertion::Skipped)
        exp = true
      else
        raise e
      end
    rescue Exception => e
      exp = args.any? {|ex| e.is_a?(ex) }
    end
    assert(exp, "Expected block to raise an exception of #{args.inspect}")
  end
  
  # オブジェクトが指定したメソッドを持つことを表明する
  # @param [Object] 対象のオブｈジェクト
  # @param [Symbol] 確認するメソッド名
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_respond_to(object, method_name, message = nil)
    assert(object.respond_to?(method_name), message, "Expected #{object.inspect} to respond to #{method_name}")
  end

  # 現在値が期待値と同じオブジェクトであることを表明する
  # @param [Object] expected 期待値
  # @param [Object] actual 現在値
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_same(expected, actual, message = nil)
    assert(expected.equal?(actual), message, "Expected #{actual.inspect} to be same as #{expected.inspect}")
  end

  # 現在値が期待値と同じオブジェクトでないことを表明する
  # @param [Object] expected 期待値
  # @param [Object] actual 現在値
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_not_same(expected, actual, message = nil)
    assert(expected.equal?(actual).!, message, "Expected #{actual.inspect} not to be same as #{expected.inspect}")
  end

  # 指定したメソッドを呼び出した結果が真であることを表明する
  # @param [Array] レシーバー、メソッド、引数をまとめた配列
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_send(array, message = nil)
    receiver, method, *args = array
    assert(receiver.__send__(method, *args), message, "Expected #{receiver.inspect}.#{method}(#{args.inspect}) to return true")
  end

  # ブロックが指定したタグをthrowすることを表明する
  # @param [Object] tag throwするはずのタグ
  # @param [String] messages 失敗時に表示するメッセージ
  def assert_throws(tag, message = nil)
    caught = true
    catch(tag) do
      yield
      caught = false
    end
    assert(caught, message, "Expected #{tag} to be thrown")
  end

end
