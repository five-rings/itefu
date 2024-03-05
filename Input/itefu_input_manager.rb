=begin
  入力関連の管理を行うクラス
=end
class Itefu::Input::Manager < Itefu::System::Base

  # 入力の意味とキーの対応付けを設定する
  # @param [Object] id 任意の識別子
  # @param [Input::Semantics] semantics
  # @return [Itefu::Input::Manager] レシーバーを返す
  def add_semantics(id, semantics)
    @semanticses[id] = semantics
    add_status(*semantics.status_param)
    @dirty = true
    self
  end

  # add_semanticsしたものを削除する
  # @return [Object|NilClass] 削除したキーまたはnil
  def remove_semantics(id)
    @semanticses.delete(id)
  end

  # semantingsとstatusのキー割り当てを更新する
  # @note add_semanticsした場合は自動的に呼ばれる
  # @note 既に登録したsemanticsを書き換えた場合などに呼ぶ
  def reset_key_mapping
    @statuses.each do |param, status|
      keys = @semanticses.each_value.grep(->(s) { param == s.status_param }, &:all_entities)
      keys.flatten!
      keys.compact!
      keys.uniq!
      status.setup(keys)
    end
    @dirty = false
  end

  # キー入力状態を管理するクラスを追加する
  # @note semantics追加時に自動設定されるので通常は設定しなくて良い
  # @param [Itefu::Input::Status::Base|NilClass] status_klass 追加したい管理クラスの型
  def add_status(status_klass, *status_args)
    args = status_klass, *status_args
    return self if status_klass.nil? || @statuses.has_key?(args)
    @statuses[args] = status_klass.new(*status_args)
    self
  end

  # add_statusしたものを削除する
  # @return [Itefu::Input::Status::Base|NilClass] 削除したキーまたはnil
  def remove_status(status_klass, *status_args)
    args = status_klass, *status_args
    @statuses.delete(args)
  end

  # @return [Boolean] 入力を受け付けているか
  def paused?; @paused; end

  # 入力を受け付けるようにする
  def resume; @paused = false; end
  
  # 入力を受け付けないようにする
  def pause; @paused = true; end

  # @return [Boolean] キーが押されているか
  def pressed?(mean, force = false)
    key_check(mean, :pressed?, force)
  end
  
  # @return [Boolean] 何らかのキーが押されているか
  def pressed_any?(force = false)
    key_check_any(:pressed?, force)
  end

  # @return [Boolean] いままで押されていなかったキーが入力されたか
  def triggered?(mean, force = false)
    key_check(mean, :triggered?, force)
  end
  
  # @return [Boolean] 何らかのキーが押されたか
  def triggered_any?(force = false)
    key_check_any(:triggered?, force)
  end

  # @return [Boolean] いままで押されていたキーが離されたか
  def released?(mean, force = false)
    key_check(mean, :released?, force)
  end
  
  # @return [Boolean] 何らかのキーが離されたか
  def released_any?(force = false)
    key_check_any(:released?, force)
  end

  # @return [Boolean] キーがおされ続けているか
  # @note pressed?な場合に、リピート間隔に応じて定期的にtrueを返す
  def repeated?(mean, force = false)
    key_check(mean, :repeated?, force)
  end

  # @return [Boolean] 何らかのキーが押され続けているか
  def repeated_any?(force = false)
    key_check_any(:repeated?, force)
  end

  # @return [Fixnum] ポインティングデバイスの横座標
  def position_x
    optional_value(:position_x)
  end

  # @return [Fixnum] ポインティングデバイスの縦座標
  def position_y
    optional_value(:position_y)
  end
  
  # @return [Fixnum] スクロールデバイスの横移動量
  def scroll_x
    optional_value(:scroll_x, 0)
  end
  
  # @return [Fixnum] スクロールデバイスの縦移動量
  def scroll_y
    optional_value(:scroll_y, 0)
  end
  
  # add_statusしたクラスを探す
  # @return [NilClass|Itefu::Input::Status::Base]
  def find_status(status_klass, *status_args)
    args = status_klass, *status_args
    @statuses[args]
  end

private

  def on_initialize
    @semanticses = {}
    @statuses = {}
    @paused = false
  end

  def on_update
    reset_key_mapping if @dirty
    @statuses.each_value(&:update)
  end

  # 指定された意味のキーの入力状態を確認する
  # @return [Boolean] 指定されたキーの状態にあるか
  # @param [Object] mean semanticsに設定したキーの意味
  # @param [Symbol] method キーの状態をチェックするメソッド名
  # @param [Boolean] force ポーズ中でも強制的にチェックするか
  def key_check(mean, method, force)
    return false if (@paused && force.!)

    @semanticses.each_value.any? do |semantics|
      status = @statuses[semantics.status_param]
      semantics.entities(mean).any? do |code|
        status.send(method, code)
      end if status
    end
  end
  
  # 指定された入力状態に何らかのキーがなっているか確認する
  # @return [Boolean] 指定されたキーの状態にあるか
  # @param [Symbol] method キーの状態をチェックするメソッド名
  # @param [Boolean] force ポーズ中でも強制的にチェックするか
  def key_check_any(method, force)
    return false if (@paused && force.!)

    @statuses.each_value do |status|
      return true if status.instance_eval {
        @key_codes.any? {|code| self.send(method, code) }
      }
    end
    false
  end

public
  # 指定されたプロパティを実装しているstatusがあれば値を返す
  # @return [Fixnum] 指定されたメソッドの値
  # @param [Symbol] method statusが実装するプロパティ
  # @param [Fixnum] default 値を取得できても、この値の場合は無視する
  # @note statusesを追加された順に探し見つかればその時点で値を返す
  def optional_value(method, default = nil)
    @statuses.each_value do |status|
      v = status.optional_value(method)
      next if v.nil?
      next unless default.nil? || v != default
      return v
    end
    default
  end

end
