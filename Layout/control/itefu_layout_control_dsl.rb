=begin
  Layoutシステム/定義ファイルをDSL風に居術するためのヘルパー
=end
module Itefu::Layout::Control::DSL
  # 子コントロールの追加の実装
  def add_child_control(klass, *args); raise Itefu::Layout::Definition::Exception::NotImplemented; end

  # アニメーションを追加する
  def add_animation(id, klass, *args); raise Itefu::Layout::Definition::Exception::NotImplemented; end

  # 子コントロールを追加する
  # @param [Class] klass 生成するコントロールの型
  # @param [Array] args コントロールの生成時に渡す任意のパラメータ
  # @param [Proc] block 生成後にinstance_evalされる
  # @return [Control::Base] 生成したコントロールを返す
  def _(klass, *args, &block)
    child = add_child_control(klass, *args)
    child.instance_eval(&block) if block
    child
  end

  # 属性を設定する
  def attribute(hash)
    hash.each do |key, value|
      send("#{key}=", value)
    end
  end

  # @return [Color] Colorのインスタンスを生成して返す
  def color(r, g, b, a = 0xff)
    Itefu::Layout::Definition::Color.create(r, g, b, a)
  end

  # @return [Color] 色を定数定義して返す
  def const_color(r, g, b, a = 0xff)
    root.view.const_color(r, g, b, a)
  end
  
  # @return [Box] ボックスを設定する
  def box(*args)
    Itefu::Layout::Definition::Box.new(*args)
  end
  
  # @return [Box] ボックスを定数定義して返す
  def const_box(t, r = nil, b = nil, l = nil)
    root.view.const_box(t, r||t, b||t, l||r||t)
  end
  
  # @return [Rect] 矩形を指定する
  def rect(*args)
    Itefu::Layout::Definition::Rect.new(*args)
  end
  
  # @return [Rect] 矩形を定数定義して返す
  def const_rect(*args)
    root.view.const_rect(*args)
  end

  # @return [Tone] 色調を指定する
  def tone(*args)
    Itefu::Layout::Definition::Tone.new(*args)
  end

  # @return [Tone] 色調を定数定義して返す
  def const_tone(*args)
    root.view.const_tone(*args)
  end

  # @return [Bitmap] 読み込んだbitmapデータ
  # @param [Array] args コントロールごとに実装する任意の引数
  def image(*args)
    load_image(*args)
  end

  # Background用の画像読み込み
  def bg_image(*args)
    load_bg_image(*args)
  end
  
  # attributeに, 新しくviewportを作成して, 設定する
  # @return [Viewport] 設定したviewport
  def assign_viewport(z, *args)
    Itefu::Rgss3::Viewport.new(*args).auto_release {|vp|
      vp.z = z
      self.viewport = vp
    }
  end

  # 子階層にフォーカスを移動する
  def push_focus(id)
    root.view.push_focus(id)
  end
  
  # フォーカスを親階層に戻す
  def pop_focus
    root.view.pop_focus
  end
  
  # 同じ階層のままフォーカスを変更する
  def switch_focus(id)
    root.view.switch_focus(id)
  end
  
  # 階層を全てリセットしフォーカスを設定する
  def reset_focus(id)
    root.view.reset_focus(id)
  end
  
  # 指定したコントロールにフォーカスが当たるまで階層を戻していく
  def rewind_focus(id)
    root.view.rewind_focus(id)
  end
  
  # メッセージIDでテキストの内容を指定する
  def message(id, text_id)
    root.view.message(id, text_id)
  end
  
  # @return [Itefu::Animation::KeyFrame] アニメーションを設定する
  def animation(id, klass = nil, *args, &block)
    add_animation(id, klass || Itefu::Layout::KeyFrame, *args, &block)
  end
  
  # @return [Itefu::Animation::KeyFrame] 複数の他のアニメを再生するアニメを設定する
  def composite_animation(anime_id, targets = [])
    view = self.root.view
    animation(id, Itefu::Animation::Base) do
      starter {
        @animes = targets.map {|target|
          view.play_animation(target, anime_id)
        }.compact
      }
      updater {
        finish if @animes.all?(&:finished?)
      }
    end
  end

  # アニメーションを再生する
  def play_animation(anime_id, *args)
    root.view.play_animation(self, anime_id, *args)
  end

  # 保持する値を取り出す  
  def unbox(value)
    case value
    when Itefu::Layout::Control::Bindable::BindingObject
      value.unbox
    when Itefu::Layout::Observable
      value.value
    else
      value
    end
  end

  # 値をobservableに変換する
  def observable(value)
    Itefu::Layout::ObservableObject.new(value)
  end
  
  # 時:分:秒を数値に変換する
  def time(hour, min, sec)
    hour * 3600 + min * 60 + sec
  end
  
  # 数値から秒だけを取り出す
  def second(time)
    time % 60
  end
  
  # 数値から分だけを取り出す
  def minute(time)
    time / 60 % 60
  end
  
  # 数値から時間だけを取り出す
  def hour(time)
    time / 3600
  end
  
  # 無名再帰
  def recursive(*args, &block)
    Utility::Function.recursive(*args, &block)
  end

  # 変数定義
  def define(name, value)
    root.view.define(name, value)
  end
  
  # 変数定義の削除
  def undefine(name)
    root.view.undefine(name)
  end
  
  # 変数が定義されているか
  def defined?(name)
    root.view.defined?(name)
  end
  
  # 定義された変数の値
  def defined_value(name)
    root.view.defined_value(name)
  end

private
  def attribute_of_ancestor(name)
    c = self
    until c.nil? || c.respond_to?(name)
      c = c.parent
    end
    c.send(name) if c
  end

  def item
    attribute_of_ancestor(:item)
  end
  
  def item_index
    attribute_of_ancestor(:item_index)
  end

end
