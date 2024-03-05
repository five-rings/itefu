=begin
  Mutexにsynchronizeを追加する
=end
class Mutex
  def synchronize
    lock
    begin
      yield
    ensure
      unlock
    end
  end
end
