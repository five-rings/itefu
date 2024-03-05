=begin
  配列関連の便利機能
=end
module Itefu::Utility::Array
class << self

  # 二分探索を行う
  # @return [Fixnum|NilClass] 値が見つかればその添え字を、見つからなければNilClassを返す
  # @param [Comparable] value 探索する比較可能な値
  # @param [Array<Object>] sorted_array ソート済み配列
  # @param [Boolean] returns_last_index 値が発見できなかった際に、nilではなく最後にチェックした添え字を返す
  # @yield [Object] 必要であればsorted_arrayから比較に使う値を取り出すProcを指定する
  def binary_search(value, sorted_array, returns_last_index = false)
    left = 0
    right = sorted_array.size - 1
    mid = 0
    if block_given?
      while left <= right
        mid = left + (right - left) / 2
        v = yield(sorted_array[mid])
        if v > value
          right = mid - 1
        elsif v < value
          left = mid + 1
        else
          return mid
        end
      end
    else
      while left <= right
        mid = left + (right - left) / 2
        v = sorted_array[mid]
        if v > value
          right = mid - 1
        elsif v < value
          left = mid + 1
        else
          return mid
        end
      end
    end
    returns_last_index ? mid : nil
  end

  # @return [Fixnum] 指定した値を超える最初の要素の添え字
  # @param [Comparable] value 探したい値
  # @param [Array<Object>] sorted_array 検索対象
  # @yield [Object] 必要であればsorted_arrayから比較に使う値を取り出すProcを指定する
  def upper_bound(value, sorted_array, &block)
    index = binary_search(value, sorted_array, true, &block)
    if block
      while (v = sorted_array[index]) && (block.call(v) <= value)
        index += 1
      end
    else
      while (v = sorted_array[index]) && (v <= value)
        index += 1
      end
    end
    index
  end

  # @return [Fixnum] 指定した値以上になる最初の要素の添え字
  # @param [Comparable] value 探したい値
  # @param [Array<Object>] sorted_array 検索対象
  # @yield [Object] 必要であればsorted_arrayから比較に使う値を取り出すProcを指定する
  def lower_bound(value, sorted_array, &block)
    index = binary_search(value, sorted_array, true, &block)
    if block
      while (v = sorted_array[index]) && (block.call(v) < value)
        index += 1
      end
      while (v = sorted_array[index-1]) && (block.call(v) == value)
        index -= 1
      end 
    else
      while (v = sorted_array[index]) && (v < value)
        index += 1
      end
      while (v = sorted_array[index-1]) && (v == value)
        index -= 1
      end 
    end
    index
  end

  # ソート済み配列にソートを維持したまま値を挿入する
  # @return [Array<Object>] ソート済みの配列
  # @param [Object] element 挿入したい値、またはそれを含む要素
  # @param [Array<Object>] sorted_array ソート済み配列 (変更される)
  # @yield [Object] 必要であればelementおよびsorted_arrayから比較に使う値を取り出すProcを指定する
  def insert_to_sorted_array(element, sorted_array, &block)
    index_to_insert = upper_bound(block ? block.call(element) : element, sorted_array, &block)
    sorted_array.insert(index_to_insert, element)
  end

  # @return [Fixnum|Array|NilClass] ランダムに選ばれたitemsの添え字,またその配列
  # @params [Array] items 候補
  # @param [Random] random randを呼び出せるオブジェクト
  # @param [Fixnum|NilClass] ランダムにいくつ選ぶか, これを指定するとArrayを返す
  # @yield [Object] 必要であればitemsの各要素から重みをを取り出すProcを指定する
  # @note weight値の合計が0の場合は何も選ばずnilを返す
  # @caution countを指定した場合のindexは重複し得る
  def weighted_randomly_select(items, random = nil, count = nil)
    sum_of_weights = 0
    if block_given?
      weights = items.map {|item| sum_of_weights += yield(item) }
    else
      weights = items.map{|item| sum_of_weights += item }
    end
    if count
      return [] if sum_of_weights == 0
      count.times.map {
        value = random && random.rand(sum_of_weights) || rand(sum_of_weights)
        index = upper_bound(value, weights)
      }
    else
      return if sum_of_weights == 0
      value = random && random.rand(sum_of_weights) || rand(sum_of_weights)
      index = upper_bound(value, weights)
    end
  end

end
end
