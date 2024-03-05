=begin
  SaveDataのテストコード
=end
class Itefu::Test::SaveData < Itefu::UnitTest::TestCase

  class TestSaveData < Itefu::SaveData::Base
    attr_reader :data
    def on_new_data
      @data = {
        data: "test-data",
        value: 10,
      }
      true
    end

    def on_load(io, name)
      @data = Marshal.load(io)
      true
    end
    
    def on_save(io, name)
      Marshal.dump(@data, io)
      true
    end
    
    def ==(rhs)
      self.data == rhs.data
    end
  end

  def shutdown
    File.delete("testdata.dat")
  end

  def test_save_and_load
    savedata = Itefu::SaveData::Loader.new_data(TestSaveData)
    assert_equal("test-data", savedata.data[:data])
    assert_equal(10, savedata.data[:value])

    assert(Itefu::SaveData::Loader.save("testdata.dat", savedata))
    
    loaded = Itefu::SaveData::Loader.load("testdata.dat", TestSaveData)
    assert_not_same(savedata, loaded)
    assert_equal(savedata, loaded)
  end
  
end
