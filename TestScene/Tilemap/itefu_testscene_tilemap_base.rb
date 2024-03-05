=begin
  Tilemap関連のTestSceneの共通処理
=end
class Itefu::TestScene::Tilemap::Base < Itefu::Scene::Base
  include Itefu::Resource::Loader
  include Itefu::Resource::Container

  def tilemap_klass; raise Itefu::Exception::NotImplemented; end
  def tilemap_size; 16; end
  def move_speed; 4; end
  
  def on_initialize(map_id = nil)
    map_id ||= 1
    
    # load tilesets
    id_tilesets = load_rvdata2_resource(Itefu::Rgss3::Filename::Data::TILESETS)
    tilesets = resource_data(id_tilesets)
    
    # load map
    id_map = load_rvdata2_resource(Itefu::Rgss3::Filename::Data::MAP_n % map_id)
    map = resource_data(id_map)
    tileset = tilesets[map.tileset_id]
    
    # setup tilemap
    viewport = create_resource(Itefu::Rgss3::Viewport, 0, 0, Graphics.width, Graphics.height)
    Itefu::Debug::SplitTimer.measure("create tilemap") do
      @tilemap = create_resource(tilemap_klass, viewport)
    end
    begin
      @tilemap.cell_width = @tilemap.cell_height = tilemap_size
      @tilemap.shadow_color = Color.new(1, 0, 0x5f, 0x3f)
    rescue Itefu::Exception::NotSupported
    end
    tileset.tileset_names.each.with_index do |name, i|
      next if name.empty?
      id = load_bitmap_resource(Itefu::Rgss3::Filename::Graphics::TILESETS_s % name)
      @tilemap.bitmaps[i] = resource_data(id) if id
    end
    Itefu::Debug::SplitTimer.measure("setup tilemap") do
      @tilemap.map_data = map.data
      @tilemap.flags = tileset.flags
    end
  end
  
  def on_finalize
    finalize_all_resources
    release_all_resources
  end
  
  def on_update
    input = $itefu_application.system(Itefu::Input::Manager)
    status = input && input.find_status(Itefu::Input::Status::Win32)
    update_input(status) if status
    @tilemap.update
  end
  
  def update_input(input_status)
    if input_status.triggered?(Itefu::Input::Win32::Code::VK_SHIFT)
      rate = 2
    else
      rate = 1
    end

    case
    when input_status.triggered?(Itefu::Input::Win32::Code::VK_RETURN)
      current_size = @tilemap.cell_width
      if current_size == Itefu::Tilemap::DEFAULT_CELL_SIZE
        next_size = tilemap_size
      else
        next_size = Itefu::Tilemap::DEFAULT_CELL_SIZE
      end
      @tilemap.cell_width = @tilemap.cell_height = next_size
      sign = next_size < current_size ? -1 : 1
      @tilemap.ox = @tilemap.ox * next_size / current_size + sign * @tilemap.screen_width  * next_size / Itefu::Tilemap::DEFAULT_CELL_SIZE / 2
      @tilemap.oy = @tilemap.oy * next_size / current_size + sign * @tilemap.screen_height * next_size / Itefu::Tilemap::DEFAULT_CELL_SIZE / 2
      @tilemap.map_data = @tilemap.map_data
    when input_status.triggered?(Itefu::Input::Win32::Code::VK_ESCAPE),
         input_status.triggered?(Itefu::Input::Win32::Code::VK_RBUTTON)
         quit
    when input_status.pressed?(Itefu::Input::Win32::Code::VK_UP)
      @tilemap.oy -= move_speed * rate
    when input_status.pressed?(Itefu::Input::Win32::Code::VK_DOWN)
      @tilemap.oy += move_speed * rate
    when input_status.pressed?(Itefu::Input::Win32::Code::VK_LEFT)
      @tilemap.ox -= move_speed * rate
    when input_status.pressed?(Itefu::Input::Win32::Code::VK_RIGHT)
      @tilemap.ox += move_speed * rate
    end
  rescue Itefu::Exception::NotSupported
  end
  
end
