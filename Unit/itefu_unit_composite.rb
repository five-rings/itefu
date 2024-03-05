=begin
  他のユニットを複数まとめて呼び出すユニット
  @note 子ユニットのmanagerはcompositeでなくそのmanagerになる
=end
class Itefu::Unit::Composite < Itefu::Unit::Base
  include Itefu::Unit::Manager

  def finalize
    clear_all_units
    super
  end

  def update
    super
    update_units
  end
  
  def draw
    super
    draw_units
  end
  
  def attached(manager)
    super
    send_attached(manager)
  end
  
  def detached
    super
    send_detached
  end
  
  def signal(value, *args)
    super
    send_signal(value, *args)
  end

private
  def create_new_unit(klass, *args, &block)
    klass.new(manager, *args, &block)
  end
  
  def send_attached(manager)
    units.each {|unit| unit.attached(manager) }
  end
  
  def send_detached
    units.each(&:detached)
  end

end
