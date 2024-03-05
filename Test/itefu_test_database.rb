=begin
  Databaseのテストコード
=end
class Itefu::Test::Database < Itefu::UnitTest::TestCase

  class TestDatabase < Itefu::Database::Loader
  end
  
  class TestItems < Itefu::Database::Table::Base
  end
  
  class TestNotedTable < Itefu::Database::Table::BaseItem
    def impl_load(filename)
      ret = super
      ret.each do |item|
        next unless item
        item.note = <<-EOS
:command1
:command2=aiueo
dummy
:command3=10
        EOS
      end
      ret
    end
  end

  def test_load_table
    database = TestDatabase.new

    # 読み込み前
    assert(database.db_table_loaded?(:items).!)
    assert_raises(ArgumentError) do
      database.unload_db_table(:items)
    end

    # 読み込み
    database.load_db_table(:items, "Data/Items.rvdata2", TestItems)
    assert(database.db_table_loaded?(:items))
    assert_raises(ArgumentError) do
      database.load_db_table(:items, "Data/Items.rvdata2", TestItems)
    end

    assert_respond_to(database, :items)
    # enumerableであることを確認
    assert_kind_of(Enumerable, database.items)
    assert_respond_to(database.items, :each)
    assert_respond_to(database.items, :map)
    assert_respond_to(database.items, :select)
    # array風に使えるか確認
    assert_respond_to(database.items, :size)
    assert_respond_to(database.items, :empty?)
    # DBの内容を確認
    assert_nil(database.items[0])
    assert_not_nil(database.items[1])
    assert_nil(database.items[database.items.size])
    assert_kind_of(RPG::Item, database.items[1])

    # 解放
    database.unload_db_table(:items)
    assert(database.db_table_loaded?(:items).!)
    assert_raises(NoMethodError) do
      database.items
    end
  end

  def test_load_some_tables
    database = TestDatabase.new

    assert(database.db_table_loaded?(:items).!)
    database.load_db_table(:items, "Data/Items.rvdata2", TestItems)
    assert_respond_to(database, :items)
    assert(database.db_table_loaded?(:items))

    assert(database.db_table_loaded?(:actors).!)
    database.load_db_table(:actors, "Data/Actors.rvdata2")
    assert_respond_to(database, :actors)
    assert(database.db_table_loaded?(:actors))

    assert_not_equal(database.items, database.actors)
    assert_kind_of(RPG::Item, database.items[1])
    assert_kind_of(RPG::Actor, database.actors[1])

    database.unload_db_table(:items)
    assert(database.db_table_loaded?(:items).!)
    assert(database.db_table_loaded?(:actors))

    database.unload_db_table(:actors)
    assert(database.db_table_loaded?(:actors).!)
  end
  
  def test_load_default_table
    database = TestDatabase.new
    database.load_db_table(:items, "Data/Items.rvdata2", TestNotedTable)
    assert_respond_to(database, :items)

    item = database.items[1]
    assert_not_nil(item)
    assert_respond_to(item, :special_flags)
    assert_equal(true, item.special_flags[:command1])
    assert_equal("aiueo", item.special_flags[:command2])
    assert_equal("10", item.special_flags[:command3])
    assert_nil(item.special_flags[:dummy])
  end

end
