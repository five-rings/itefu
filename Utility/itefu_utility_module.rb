=begin
  モジュール関連の便利機能  
=end
module Itefu::Utility::Module
class << self

  # 定義順に数値が増える定数を定義する
  # @param [Class] klass 定義するクラス・モジュール
  # @param [Array<Symbol>] 定数の名前
  # @param [Fixnum] start 最初の値
  # @yield indexを渡しブロックを呼び結果を定数の値に使う
  def declare_enumration(klass, list, start = 0)
    if block_given?
      list.each.with_index(start) do |name, index|
        klass.const_set(name, yield(index))
      end
    else
      list.each.with_index(start) do |name, index|
        klass.const_set(name, index)
      end
    end
  end

  # 定数の値を得る
  # @param [Class] 定数の定義されているクラス・モジュール
  # @return [Array<Object>] 定数の値の配列 unlessbblock_given?
  # @yield 定義されている定数の分だけ、その値と名前を引数にしてブロックを呼ぶ
  def const_values(klass)
    if block_given?
      klass.constants.each do |symbol|
        yield(klass.const_get(symbol), symbol)
      end
    else
      klass.constants.map {|symbol| klass.const_get(symbol) }
    end
  end
  
  # 定数を定義する
  # @note 定数が定義されていれば何もせず、定義されていなければ値を設定する
  # @param [Object] object 定数を設定する対象
  # @param [Symbol] name 定数名
  # @yield 返り値を定数として設定する
  def define_const(object, name)
    unless object.const_defined?(name)
      object.const_set name, yield
    end
  end
  
  # 定数を遅延定義する
  # @note 定数風の名前のメソッドを定義し、呼ばれた時点ではじめてオブジェクトを生成して返すようにする
  # @param [Class] klass 定義するクラス・モジュール
  # @param [Symbol] name メソッド名
  # @param [Class] value_klass 生成するオブジェクトの型
  # @param [ARray] value_args value_klassをnewする際に渡す引数
  def declare_lazy_constant(klass, name, value_klass, *value_args)
    klass.class_eval(<<-EOS)
      def #{name}
        @@#{name} ||= #{value_klass}.new(#{value_args.join(",")}).freeze
      end
    EOS
  end
  
#ifdef :ITEFU_DEVELOP
  # 特定のクラスにinclude/extendされることを期待するModuleを作成する
  # @param [Class|Module] klass このクラスを継承かmix-inしていることを期待する
  # @return [Module] 期待に沿わないとAssertionFaildを投げるモジュール
  def expect_for(klass)
    @@modules_expect_for_klass ||= {}
    @@modules_expect_for_klass[klass] ||= Module.new do |md|
      define_method(:extend_object) do |object|
        ITEFU_DEBUG_ASSERT(object.is_a?(klass), "#{object.class} expects for #{klass}")
        super(object)
      end
      define_method(:append_features) do |included_klass|
        ITEFU_DEBUG_ASSERT((Class === included_klass).! || included_klass.ancestors.include?(klass), "#{included_klass} expects for #{klass}")
        super(included_klass)
      end
      define_method(:included) do |included_klass|
        super(included_klass)
        included_klass.extend md
      end
    end
  end

  # 特定のモジュールをmix-inすることを想定していないことを表明する
  # @param [Module] klass このモジュールはmix-inできなくする
  # @return [Module] 期待に沿わないとAssertionFaildを投げるモジュール
  def unexpect_for(klass)
    @@modules_unexpect_for_klass ||= {}
    @@modules_unexpect_for_klass[klass] ||= Module.new do |md|
      define_method(:extend) do |*modules|
        modules.each do |m|
          ITEFU_DEBUG_ASSERT(m != klass && m.include?(klass).!, "#{self} unexpected for #{klass}")
        end
        super(*modules)
      end
      define_method(:include) do |*modules|
        modules.each do |m|
          ITEFU_DEBUG_ASSERT(m != klass && m.include?(klass).!, "#{self} unexpected for #{klass}")
        end
        super(*modules)
      end
    end
  end
#endif

end
end

