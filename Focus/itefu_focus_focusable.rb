=begin
  フォーカスを得られるクラスのインターフェイス
=end
module Itefu::Focus::Focusable
  attr_accessor :focus      # [Boolean] フォーカスを得ているか
  attr_accessor :focused    # [Proc] フォーカスを得た際に呼ばれる
  attr_accessor :unfocused  # [Proc] フォーカスを得た際に呼ばれる
  attr_accessor :custom_operation     # [Proc]
  attr_accessor :operation_instructed # [Proc] 
  def focused?; @focus; end

  # フォーカスを得た際に呼ばれる
  def on_focused; end

  # フォーカスを失った際に呼ばれる
  def on_unfocused; end
  
  # 外部から操作された際に呼ばれる
  def on_operation_instructed(code, *args); end
  
  # 外部から何かしらの操作を受け付ける
  # @note custom_operationでnilを返すと処理を中断する
  def operate(code, *args)
    code = custom_operation.call(self, code, *args) if custom_operation
    if code
      on_operation_instructed(code, *args)
      operation_instructed.call(self, code, *args) if operation_instructed
    end
  end

  def initialize(*args)
    @focus = false
    super
  end

  # フォーカスを設定する
  # @param [Boolean] フォーカスを得ているか
  def focus=(value)
    if @focus != value
      @focus = value
      if value
        on_focused
        focused.call(self) if focused
      else
        on_unfocused
        unfocused.call(self) if unfocused
      end
    end
  end
  
  # Focus::Controllerから透過的に呼ばれるためのインターフェイス
  def focused_instance; self; end

end
