=begin
  実際のキーコードと入力の意味とを変換する
=end
class Itefu::Input::Semantics
  attr_reader :status_param
  
  def initialize(status_klass, *status_args)
    @status_param = status_klass, *status_args
    @entities = {}
  end

  # 登録されたキー情報をすべてクリアする
  # @return [Semantics] レシーバーを返す
  def clear_entities
    @entities.clear
    self
  end

  # @return [Array<Object>] 登録されたキー情報
  # @param [Object] キーの意味
  def entities(mean)
    @entities[mean] ||= []
  end

  # @return [Array<Array<Object>>] 登録されている全てのキー情報
  def all_entities
    @entities.values
  end

  # 意味に対応するキーを定義する
  # @param [Object] mean 意味
  # @param [Array<Object>] args 意味に対応するキー
  # @return [Semantics] レシーバーを返す
  def define(mean, *args)
    entities(mean).concat(args).uniq!
    self
  end

  # 意味に対応しているキーを削除する
  # @param [Object] mean 意味
  # @param [Array<Object>] args 削除するキー
  # @return [Semantics] レシーバーを返す
  def undefine(mean, *args)
    e = entities(mean)
    args.each do |entity|
      e.delete(entity)
    end
    self
  end

  # 意味に対応しているキーをすべて削除する
  # @param [Object] mean 意味
  # @return [Semantics] レシーバーを返す
  def undefine_all(mean)
    entities(mean).clear
    self
  end

end
