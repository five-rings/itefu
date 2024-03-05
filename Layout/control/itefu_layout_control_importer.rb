=begin
  Layoutシステム/他のファイルを読み込むコントロール
=end
class Itefu::Layout::Control::Importer < Itefu::Layout::Control::Decorator
  def debug?; root.debug?; end

  def self.new(*args)
    # @note Importerのfinalizeが呼ばれないが, Importer < Decorator には解放しなければならないものはないので, 構わない.
    super.child
  end

  def initialize(parent, signature, context = nil)
    super(parent)    
    view = root.view
    script = view.signature_to_layout(signature)
    context = context || view.context
    debug = debug?
    this = self
    this.instance_eval(script, view.signature_to_filename(signature))
  end

  # 子コントロールの生成
  def create_child_control(klass, *args)
    # parentをimporterでなくそのparentに差し替えて生成する
    klass.new(parent, *args)
  end
  
  # ビューワーなど確認時専用のサイズ設定
  def design_size(w, h); end

end
