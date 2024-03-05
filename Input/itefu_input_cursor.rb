=begin
  マウスの位置にカーソルを表示する
=end
module Itefu::Input::Cursor

  module Initializer
    def extended(system)
      ITEFU_DEBUG_ASSERT(Itefu::Input::Manager === system)
      system.initialize_cursor_variables
    end

    def included(klass)
      ITEFU_DEBUG_ASSERT(Module === klass)
      klass.extend(Initializer)
    end
  end
  extend Initializer
  
  def setup_sprite(sprite); raise Itefu::Exception::NotImplemented; end

  def initialize_cursor_variables
    return if @sprite
    @sprite = Itefu::Rgss3::Sprite.new
    setup_sprite(@sprite)
  end

  def on_update
    super
    @sprite.x = position_x
    @sprite.y = position_y
    @sprite.update
  end
  
  def on_finalize
    super
    @sprite = @sprite.swap(nil)
  end

end
