=begin
  RGSS3のテストコード
=end
class Itefu::Test::Rgss3 < Itefu::UnitTest::TestCase

  def test_dispose_bitmap
    bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    bitmap.dispose
    assert(bitmap.disposed?)

    bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    bitmap.ref_attach
    bitmap.dispose
    assert(bitmap.disposed?.!)
    bitmap.dispose
    assert(bitmap.disposed?)
  end
  
  def test_dispose_viewport
    viewport = Itefu::Rgss3::Viewport.new
    viewport.dispose
    assert(viewport.disposed?)

    viewport = Itefu::Rgss3::Viewport.new
    viewport.ref_attach
    viewport.dispose
    assert(viewport.disposed?.!)
    viewport.dispose
    assert(viewport.disposed?)
  end

  def test_dispose_sprite
    sprite = Itefu::Rgss3::Sprite.new
    sprite.dispose
    assert(sprite.disposed?)
    
    sprite = Itefu::Rgss3::Sprite.new
    sprite.ref_attach
    sprite.dispose
    assert(sprite.disposed?.!)
    sprite.dispose
    assert(sprite.disposed?)
  end
  
  def test_dispose_plane
    plane = Itefu::Rgss3::Plane.new
    plane.dispose
    assert(plane.disposed?)

    plane = Itefu::Rgss3::Plane.new
    plane.ref_attach
    plane.dispose
    assert(plane.disposed?.!)
    plane.dispose
    assert(plane.disposed?)
  end
  
  def test_dispose_window
    window = Itefu::Rgss3::Window.new(0, 0, 0, 0)
    window.dispose
    assert(window.disposed?)

    window = Itefu::Rgss3::Window.new(0, 0, 0, 0)
    window.ref_attach
    window.dispose
    assert(window.disposed?.!)
    window.dispose
    assert(window.disposed?)
  end
  
  def test_dispose_tilemap
    tilemap = Itefu::Rgss3::Tilemap.new
    tilemap.dispose
    assert(tilemap.disposed?)

    tilemap = Itefu::Rgss3::Tilemap.new
    tilemap.ref_attach
    tilemap.dispose
    assert(tilemap.disposed?.!)
    tilemap.dispose
    assert(tilemap.disposed?)
  end
  
  def test_dispose_tilemap_predraw
    tilemap = Itefu::Rgss3::Tilemap::Predraw.new
    tilemap.dispose
    assert(tilemap.disposed?)

    tilemap = Itefu::Rgss3::Tilemap::Predraw.new
    tilemap.ref_attach
    tilemap.dispose
    assert(tilemap.disposed?.!)
    tilemap.dispose
    assert(tilemap.disposed?)
  end

  def test_dispose_tilemap_redraw
    tilemap = Itefu::Rgss3::Tilemap::Redraw.new
    tilemap.dispose
    assert(tilemap.disposed?)

    tilemap = Itefu::Rgss3::Tilemap::Redraw.new
    tilemap.ref_attach
    tilemap.dispose
    assert(tilemap.disposed?.!)
    tilemap.dispose
    assert(tilemap.disposed?)
  end

  def test_dispose_sprite_and_properties1
    sprite = Itefu::Rgss3::Sprite.new
    sprite.viewport = viewport = Itefu::Rgss3::Viewport.new
    sprite.bitmap = bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    
    viewport.dispose
    assert(viewport.disposed?.!)
    bitmap.dispose
    assert(bitmap.disposed?.!)
    
    sprite.dispose
    assert(sprite.disposed?)
    assert(bitmap.disposed?)
    assert(viewport.disposed?)
  end

  def test_dispose_sprite_and_properties2
    sprite = Itefu::Rgss3::Sprite.new
    sprite.viewport = viewport = Itefu::Rgss3::Viewport.new
    sprite.bitmap = bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    
    sprite.dispose
    assert(sprite.disposed?)
    assert(bitmap.disposed?.!)
    assert(viewport.disposed?.!)

    viewport.dispose
    assert(viewport.disposed?)
    bitmap.dispose
    assert(bitmap.disposed?)
  end

  def test_dispose_plane_and_properties1
    plane = Itefu::Rgss3::Plane.new
    plane.viewport = viewport = Itefu::Rgss3::Viewport.new
    plane.bitmap = bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    
    viewport.dispose
    assert(viewport.disposed?.!)
    bitmap.dispose
    assert(bitmap.disposed?.!)
    
    plane.dispose
    assert(plane.disposed?)
    assert(bitmap.disposed?)
    assert(viewport.disposed?)
  end

  def test_dispose_plane_and_properties2
    plane = Itefu::Rgss3::Plane.new
    plane.viewport = viewport = Itefu::Rgss3::Viewport.new
    plane.bitmap = bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    
    plane.dispose
    assert(plane.disposed?)
    assert(bitmap.disposed?.!)
    assert(viewport.disposed?.!)

    viewport.dispose
    assert(viewport.disposed?)
    bitmap.dispose
    assert(bitmap.disposed?)
  end

  def test_window_and_properties1
    window = Itefu::Rgss3::Window.new(0, 0, 0, 0)
    window.viewport = viewport = Itefu::Rgss3::Viewport.new
    window.contents = bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    window.windowskin = windowskin = Itefu::Rgss3::Bitmap.new(32, 32)

    viewport.dispose
    assert(viewport.disposed?.!)
    bitmap.dispose
    assert(bitmap.disposed?.!)
    windowskin.dispose
    assert(windowskin.disposed?.!)

    window.dispose
    assert(window.disposed?)
    assert(bitmap.disposed?)
    assert(viewport.disposed?)
    assert(windowskin.disposed?)
  end

  def test_window_and_properties2
    window = Itefu::Rgss3::Window.new(0, 0, 0, 0)
    window.viewport = viewport = Itefu::Rgss3::Viewport.new
    window.contents = bitmap = Itefu::Rgss3::Bitmap.new(32, 32)
    window.windowskin = windowskin = Itefu::Rgss3::Bitmap.new(32, 32)

    window.dispose
    assert(window.disposed?)
    assert(bitmap.disposed?.!)
    assert(viewport.disposed?.!)

    viewport.dispose
    assert(viewport.disposed?)
    bitmap.dispose
    assert(bitmap.disposed?)
    windowskin.dispose
    assert(windowskin.disposed?)
  end

  def test_tilemap_and_properties1
    tilemap = Itefu::Rgss3::Tilemap.new
    tilemap.viewport = viewport = Itefu::Rgss3::Viewport.new

    viewport.dispose
    assert(viewport.disposed?.!)

    tilemap.dispose
    assert(tilemap.disposed?)
    assert(viewport.disposed?)
  end

  def test_tilemap_and_properties2
    tilemap = Itefu::Rgss3::Tilemap.new
    tilemap.viewport = viewport = Itefu::Rgss3::Viewport.new

    tilemap.dispose
    assert(tilemap.disposed?)
    assert(viewport.disposed?.!)

    viewport.dispose
    assert(viewport.disposed?)
  end
  
  def test_tilemap_predraw_and_properties1
    tilemap = Itefu::Rgss3::Tilemap::Predraw.new
    tilemap.viewport = viewport = Itefu::Rgss3::Viewport.new

    viewport.dispose
    assert(viewport.disposed?.!)

    tilemap.dispose
    assert(tilemap.disposed?)
    assert(viewport.disposed?)
  end

  def test_tilemap_predraw_and_properties2
    tilemap = Itefu::Rgss3::Tilemap::Predraw.new
    tilemap.viewport = viewport = Itefu::Rgss3::Viewport.new

    tilemap.dispose
    assert(tilemap.disposed?)
    assert(viewport.disposed?.!)

    viewport.dispose
    assert(viewport.disposed?)
  end
  
  def test_tilemap_redraw_and_properties1
    tilemap = Itefu::Rgss3::Tilemap::Redraw.new
    tilemap.viewport = viewport = Itefu::Rgss3::Viewport.new

    viewport.dispose
    assert(viewport.disposed?.!)

    tilemap.dispose
    assert(tilemap.disposed?)
    assert(viewport.disposed?)
  end

  def test_tilemap_redraw_and_properties2
    tilemap = Itefu::Rgss3::Tilemap::Redraw.new
    tilemap.viewport = viewport = Itefu::Rgss3::Viewport.new

    tilemap.dispose
    assert(tilemap.disposed?)
    assert(viewport.disposed?.!)

    viewport.dispose
    assert(viewport.disposed?)
  end
  
  def test_auto_release
    sprite = Itefu::Rgss3::Sprite.new
    b = Itefu::Rgss3::Bitmap.new(1, 1).auto_release {|bitmap|
      assert_equal(1, bitmap.ref_count)
      sprite.bitmap = bitmap
      assert_equal(2, bitmap.ref_count)
    }

    assert(b.disposed?.!)
    assert_equal(1, b.ref_count)
    
    sprite.bitmap = nil
    assert(b.disposed?)
    assert_equal(0, b.ref_count)
  end
  
  def test_resource_pool
    pool = Itefu::Rgss3::Resource::Pool
    pool.create(2, Itefu::Rgss3::Window, 0, 0, 10, 10)

    w1 = pool.assign(Itefu::Rgss3::Window, 0, 0, 10, 10)
    assert_instance_of(Itefu::Rgss3::Window, w1)

    w2 = pool.assign(Itefu::Rgss3::Window, 0, 0, 10, 10)
    assert_instance_of(Itefu::Rgss3::Window, w2)

    w3 = pool.assign(Itefu::Rgss3::Window, 0, 0, 10, 10)
    assert_nil(w3)

    w2.dispose
    w4 = pool.assign(Itefu::Rgss3::Window, 0, 0, 10, 10)
    assert_same(w2, w4)

    w4.dispose
    assert(w2.disposed?.!)

    pool.remove_all_resources
    assert(w2.disposed?)
    assert(w1.disposed?.!)

    w1.dispose
    assert(w1.disposed?.!)
    pool.remove_all_resources
    assert(w1.disposed?)
  end
  
end
