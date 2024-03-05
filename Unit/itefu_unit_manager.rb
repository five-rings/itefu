=begin
  ユニットを登録するモジュール
=end
module Itefu::Unit::Manager

  def initialize(*args)
    @sorted_units = []
    @units = {}
    super
  end

  # @return [Array<Unit::Base>] priority順にソートされたユニット
  def units
    @sorted_units
  end

  # @return [Unit::Base] 指定したIDのユニット
  # @param [Symbol] unit_id ユニットID
  def [](unit_id)
    unit(unit_id)
  end
  
  # @return [Unit::Base] 指定したIDのユニット
  # @param [Symbol] unit_id ユニットID
  def unit(unit_id)
    @units[unit_id]
  end

  # 登録したユニットを全て解除する
  def clear_all_units
    @sorted_units.each(&:finalize)
    @sorted_units.clear
    @units.clear
  end
 
  # 登録したユニットを全て管理対象から外す
  def detach_all_units
    @sorted_units.each(&:detached)
    @sorted_units.clear
    @units.clear
  end
 
  # 登録したユニットの更新処理を呼ぶ  
  def update_units
    @sorted_units.each(&:update)
  end
  
  # 登録したユニットの描画処理を呼ぶ  
  def draw_units
    @sorted_units.each(&:draw)
  end
  
  # ユニットを追加する
  # @param [Class] klass 追加するユニットの型
  # @param [Array] *args 任意の引数
  # @return [Unit::Base] 追加したユニットのインスタンス
  def add_unit(klass, *args, &block)
    add_unit_with_priority(nil, klass, *args, &block)
  end
  
  # priorityを指定してユニットを追加する
  # @param [Fixnum] priority 優先度
  # @param [Class] klass 追加するユニットの型
  # @param [Array] *args 任意の引数
  # @return [Unit::Base] 追加したユニットのインスタンス
  def add_unit_with_priority(priority, klass, *args, &block)
    impl_attach_unit(create_new_unit(klass, *args, &block), priority, @lazy_sort)
  end

  # ユニットのインスタンスを管理対象に追加する
  # @param [Unit::Base] unit 追加するユニットのインスタンス
  # @param [Fixnum] priority 優先度
  # @return [Unit::Base] 追加したユニットのインスタンス
  def attach_unit(unit, priority = nil)
    ITEFU_DEBUG_ASSERT(unit.nil?.!)
    ITEFU_DEBUG_ASSERT(@units.has_key?(unit.unit_id).!, "Unit Id.#{unit.unit_id} is duplicated.")
    impl_attach_unit(unit, priority, @lazy_sort)
    unit.attached(self)
    unit
  end
   
  # 複数のユニットのインスタンスを管理対象に追加する
  # @param [Array<Unit::Base>] units 追加するユニットのインスタンス
  def attach_units(units)
    lazy_sort {
      units.each do |unit|
        attach_unit(unit)
      end
    }
  end
 
  # ユニット追加時にはソートせず、ブロックの評価が終わった後にまとめてソートする
  # @yield [self] add_unit/attach_unit を呼ぶためのブロック
  # @return [Object] ブロックの返り値をそのまま返す
  def lazy_sort
    @lazy_sort = true
    ret = yield(self)
    @lazy_sort = false
    @sorted_units.sort_by!(&:priority)
    ret
  end

  # 登録済みのユニットを削除する  
  # @param [Unit::Base] unit 削除するユニットのインスタンス
  # @return [Unit::Base] 削除したユニットのインスタンス
  def remove_unit(unit)
    unit = impl_detach_unit(unit)
    unit.finalize if unit
    unit
  end
  
  # 登録済みの複数のユニットを削除する  
  # @param [Array<Unit::Base>] units 削除するユニットのインスタンス
  # @warning unitsが実際には登録されていなくてもfinalizeを呼ぶ
  def remove_units(units)
    impl_detach_units(units)
    units.each(&:finalize)
    units
  end
  
  # 条件に合致するユニットを削除する
  def remove_units_if(&block)
    @sorted_units.delete_if do |unit|
      if block.call(unit)
        unit.finalize
        @units.delete(unit.unit_id)
        true
      end
    end
  end
  
  # 登録済みのユニットを管理対象から外す
  # @note detachする際はfinalizeが呼ばれずdetachedが呼ばれる
  # @param [Unit::Base] unit 削除するユニットのインスタンス
  # @return [Unit::Base] 削除したユニットのインスタンス
  def detach_unit(unit)
    unit = impl_detach_unit(unit)
    unit.detached if unit
    unit
  end
  
  # 登録済みの複数のユニットを管理対象から外す
  # @param [Array<Unit::Base>] units 削除するユニットのインスタンス
  # @warning unitsが実際には登録されていなくてもdetachedを呼ぶ
  def detach_units(units)
    impl_detach_units(units)
    units.each(&:detached)
    units
  end
 
  # 条件に合致するユニットを管理対象から外す
  def detach_units_if(&block)
    @sorted_units.delete_if do |unit|
      if block.call(unit)
        unit.detached
        @units.delete(unit.unit_id)
        true
      end
    end
  end
  
  # 管理しているユニットにシグナルを送る
  # @param [Symbol] signal シグナル
  # @param [Array] *args 任意の引数
  def send_signal(signal, *args)
    @sorted_units.each do |unit|
      unit.signal(signal, *args)
    end
  end

private
  # ユニットのインスタンスを生成する
  # @return [Unit::Base] 生成したユニットのインスタンス
  # @param [Class] klass 追加するユニットの型
  # @param [Array] *args 任意の引数
  def create_new_unit(klass, *args, &block)
    klass.new(self, *args, &block)
  end

  # インスタンスを管理対象に加える
  # @warning not_to_sort を　true で呼んだ場合、呼び出し側で確実に @sorted_units をソートしなければならない
  # @param [Unit::Base] unit 追加するユニットのインスタンス
  # @param [Fixnum] priority 優先度
  # @param [Boolean] not_to_sort ソートせずに追加するか
  # @return [Unit::Base] 追加したユニットのインスタンス
  def impl_attach_unit(unit, priority, not_to_sort = false)
    unit.priority = priority if priority
    if not_to_sort 
      @sorted_units << unit
    else
      Itefu::Utility::Array.insert_to_sorted_array(unit, @sorted_units, &:priority)
    end
    @units[unit.unit_id] = unit
    unit
  end
  
  # インスタンスを管理対象から除外する
  # @param [Unit::Base] unit 削除するユニットのインスタンス
  # @return [Unit::Base] 削除したユニットのインスタンス
  def impl_detach_unit(unit)
    @sorted_units.delete(unit)
    @units.delete(unit.unit_id)
  end
  
  # 複数のインスタンスを管理対象から除外する
  # @param [Array<Unit::Base>] units 削除するユニットのインスタンス
  def impl_detach_units(units)
    @sorted_units -= units
    units.each do |unit|
      @units.delete(unit.unit_id)
    end
  end

end
