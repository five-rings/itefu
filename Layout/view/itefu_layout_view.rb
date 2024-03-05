=begin
  Layoutシステム/MVVMのView
=end
module Itefu::Layout::View
  include Itefu::Animation::Player
  include Itefu::Language::Loader
  attr_accessor :focus
  attr_accessor :viewport
  attr_reader :context
  attr_reader :root_control

  # レイアウトデータの識別子を実際に読み込める形に変換する
  def signature_to_layout(signature)
    raise Itefu::Layout::Definition::Exception::NotImplemented
  end
  def signature_to_filename(signature); "(eval: #{signature})"; end
  
  # レイアウト定義を読み込む
  def load_layout(signature, context = nil)
    @context = context
    @root_control.import(signature)
    @root_control.update
    @root_control.rearrange
    @root_control.notify_of_layouted
  end

  # レイアウトをDecorator/Compositeの子として読み込む
  def add_layout(name, signature, context = nil, importer = Itefu::Layout::Control::Importer)
    @imported ||= []
    c = control(name).add_child_control(importer, signature, context)
    @imported << c
    c
  end

  # importされたコントロールを明示的に処理する
  # @note これを呼ばない場合でもupdaterで自動的に処理される
  def layout_imported
    unless @imported.nil? || @imported.empty?
      if @root_control
        @root_control.update
        @root_control.rearrange
      end
      @imported.each(&:notify_of_imported)
      @imported.clear
    end
  end
  
  # Viewに自動挿入されるルートコントロールの型
  def root_control_klass
    Itefu::Layout::Control::Root
  end
  
  # 入力処理
  def handle_input
    # @note 必要に応じてアプリケーション側で実装する
  end
  
  # Viewportを設定する
  def viewport=(vp)
    old = @viewport
    @viewport = Itefu::Rgss3::Resource.swap(old, vp)
    if @root_control
      if vp
        # 新しいViewportのサイズに合わせる
        rect = vp.rect
        @root_control.size(rect.width, rect.height)
      elsif old
        # 今までは、前のViewportのサイズに合っていたので、画面サイズに戻す
        @root_control.size(Graphics.width, Graphics.height)
      end
      @root_control.notify_of_viewport
    end
  end
  
  def initialize(*args)
    @context = nil
    @controls = {}
    @const_variables = {}
    @defined_values = {}
    @focus = Itefu::Focus::Controller.new
    @root_control = root_control_klass.new(self)
    @root_control.size(Graphics.width, Graphics.height)
    super
  end

  def finalize_layout
    finalize_animations
    if @root_control
      @root_control.finalize
      @root_control = nil
      @controls.clear
    end
    release_all_messages
    self.viewport = nil
  end

  def update_layout
    handle_input if focus.active?
    update_animations
    if @root_control
      @root_control.update
      @root_control.rearrange
    end
    unless @imported.nil? || @imported.empty?
      @imported.each(&:notify_of_imported)
      @imported.clear
    end
  end

  def draw_layout
    @root_control.draw if @root_control
  end


  # --------------------------------------------------
  # コントロール関連
  # 

  def control(name)
    name.is_a?(Itefu::Layout::Control::Base) ? name : @controls[name]
  end

  def register_control(name, value)
    ITEFU_DEBUG_ASSERT(name)
    ITEFU_DEBUG_ASSERT(value)
    @controls[name] = value
  end
  
  def unregister_control(name, value = nil)
    if value.nil?
      @controls.delete(name)
    else
      @controls.delete(name) if @controls.has_key?(name) && @controls.fetch(name).equal?(value)
    end
  end
  
  def [](name)
    control(name)
  end
  
  def []=(name, value)
    register_control(name, value)
  end

  # --------------------------------------------------
  # フォーカス関連
  # 

  def clear_focus
    @focus.clear
  end
  
  def push_focus(id)
    focus.push(control(id))
  end
  
  def pop_focus
    focus.pop
  end
  
  def switch_focus(id)
    focus.switch(control(id))
  end
  
  def reset_focus(id)
    focus.reset(control(id))
  end
  
  def rewind_focus(id)
    focus.rewind(control(id))
  end

  # --------------------------------------------------
  # アニメーション関連
  # 
  
  def animation_id(control_id, anime_id)
    return unless c = control(control_id)
    c.animation_key(anime_id)
  end

  alias :play_raw_animation :play_animation
  def play_animation(control_id, anime_id, *args)
    return unless c = control(control_id)
    anime = c.animation_data(anime_id)
    ITEFU_DEBUG_OUTPUT_WARNING "Animation##{anime_id} is not found in #{control_id}" unless anime
    play_raw_animation(c.animation_key(anime_id), anime, *args) if anime
  end

  # --------------------------------------------------
  # 定数関連
  # 
  
  def const_color(*args)
    get_const_variable(:color, *args) ||
    set_const_variable(
      Itefu::Layout::Definition::Color.create(*args),
      :color, *args
    )
  end
  
  def const_box(*args)
    get_const_variable(:box, *args) ||
    set_const_variable(
      Itefu::Layout::Definition::Box.new(*args),
      :box, *args
    )
  end
  
  def const_rect(*args)
    get_const_variable(:rect, *args) ||
    set_const_variable(
      Itefu::Layout::Definition::Rect.new(*args),
      :rect, *args
    )
  end

  def const_tone(*args)
    get_const_variable(:tone, *args) ||
    set_const_variable(
      Itefu::Layout::Definition::Tone.new(*args),
      :tone, *args
    )
  end

  def get_const_variable(*args)
    @const_variables[args]
  end

  def set_const_variable(value, *args)
    @const_variables[args] = value.freeze
  end

  # --------------------------------------------------
  # 変数関連
  # 
  
  def define(name, value)
    @defined_values[name] = value
  end
  
  def undefine(name)
    @defined_values.delete(name)
  end
  
  def defined?(name)
    @defined_values.has_key?(name)
  end
  
  def defined_value(name)
    @defined_values[name]
  end

end
