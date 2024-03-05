=begin
  Resourceのテストコード
=end
class Itefu::Test::Resource < Itefu::UnitTest::TestCase

  class Loader
    include Itefu::Resource::Loader
    attr_reader :cache
    def cache_instance; @cache ||= Itefu::Resource::Cache.new; end
  end
  
  class RefCount
    include Itefu::Resource::ReferenceCounter
  end
  
  class Container
    include Itefu::Resource::Container
    def size
      @contained_resources.size
    end
  end

  def setup
    @loader ||= Loader.new
  end
  
  def teardown
    @loader.release_all_resources
    @loader = nil
  end

  def test_load_bitmap
    id_window1 = @loader.load_bitmap_resource("Graphics/System/Window")
    assert_not_nil(id_window1)

    id_window2 = @loader.load_bitmap_resource("Graphics/System/Window", 0x7f)
    assert_not_nil(id_window2)

    assert_not_equal(id_window1, id_window2)

    @loader.release_resource(id_window2)
    assert_nil(@loader.resource_data(id_window2))
    
    id_window1_2 = @loader.load_bitmap_resource("Graphics/System/Window")
    assert_equal(id_window1, id_window1_2)

    @loader.release_resource(id_window1_2)
    bitmap = @loader.resource_data(id_window1)
    assert_kind_of(Bitmap, bitmap)

    @loader.release_resource(id_window1)
    assert_nil(@loader.resource_data(id_window1))
    
    assert(bitmap.disposed?)
  end
  
  def test_load_rvdata2
    id_system1 = @loader.load_rvdata2_resource("Data/MapInfos.rvdata2")
    assert_not_nil(id_system1)

    id_system2 = @loader.load_rvdata2_resource("Data/MapInfos.rvdata2")
    assert_not_nil(id_system2)
    
    assert_equal(id_system1, id_system2)

    @loader.release_resource(id_system2)
    assert_not_nil(@loader.resource_data(id_system1))

    @loader.release_resource(id_system2)
    assert_nil(@loader.resource_data(id_system1))
  end
  
  def test_reference_counter
    # count
    ref = RefCount.new
    assert_equal(1, ref.ref_count)
    assert(ref.ref_releaseable?.!)
    
    ref.ref_attach
    assert_equal(2, ref.ref_count)
    ref.ref_attach(10)
    assert_equal(12, ref.ref_count)
    
    ref.ref_detach
    assert_equal(11, ref.ref_count)
    ref.ref_detach(10)
    assert_equal(1, ref.ref_count)
    
    ref.finalize()
    assert_equal(0, ref.ref_count)
    assert(ref.ref_releaseable?)
    
    # block to be called
    ref2 = RefCount.new
    temp = 10
    assert_equal(10, temp)
    ref2.ref_detach {
      temp = 20
    }
    assert_equal(20, temp)
    
    # swap
    ref3 = RefCount.new
    ref4 = RefCount.new
    ref3.ref_attach
    ref0 = ref3.swap(ref4)
    assert_equal(ref4, ref0)
    assert_equal(1, ref3.ref_count)
    assert_equal(2, ref4.ref_count)
    ref0 = ref3.swap(nil)
    assert_nil(ref0)
    assert_equal(0, ref3.ref_count)
  end

  def test_resource_container
    container = Container.new
    dummy = container.create_resource(Itefu::Rgss3::None)
    sprite1 = container.create_resource(Itefu::Rgss3::Sprite)
    sprite2 = container.create_resource(Itefu::Rgss3::Sprite)
    viewports = container.create_resources(5, Itefu::Rgss3::Viewport)
    assert_equal(8, container.size)
    assert(dummy.disposed?.!)
    assert(sprite1.disposed?.!)
    assert(sprite2.disposed?.!)
    
    plane1 = container.change_resource(sprite1, Itefu::Rgss3::Plane)
    dummy = container.change_resource(dummy, Itefu::Rgss3::Window, 0, 0, 0, 0)
    assert_equal(8, container.size)
    assert_instance_of(Itefu::Rgss3::Window, dummy)
    assert_instance_of(Itefu::Rgss3::Plane, plane1)
    assert_equal(plane1.resource_index, sprite1.resource_index)
    assert(dummy.disposed?.!)
    assert(sprite1.disposed?)
    assert(sprite2.disposed?.!)
    assert(plane1.disposed?.!)
    
    viewports.each do |vp|
      assert(vp.disposed?.!)
    end
    container.finalize_all_resources
    assert(dummy.disposed?)
    assert(sprite1.disposed?)
    assert(sprite2.disposed?)
    assert(plane1.disposed?)
    viewports.each do |vp|
      assert(vp.disposed?)
    end
    assert_equal(0, container.size)
  end

end
