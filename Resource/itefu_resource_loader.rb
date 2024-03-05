=begin
  リソースの読み込みと、自分が読み込んだリソースをまとめて解放する機能を提供する
  任意のクラスにmix-inして使用する
=end
module Itefu::Resource::Loader
  attr_reader :resources
  @@cache = nil

  # @return [Resource::Cache] 利用するキャッシュのインスタンス
  def cache_instance
    @@cache ||= Itefu::Resource::Cache.new
  end

  # キャッシュを解放する
  # @note ゲーム終了時やリセットで再開する際に呼ぶ
  def self.release_cache
    if @@cache
      @@cache.finalize
      @@cache = nil
    end
  end

  # extend時に変数を初期化する
  def self.extended(object)
    if object.uninitialized?
      object.initialize_resource_variables
    end
  end

  # @return [Boolean] 未初期化か
  def uninitialized?
    @resources.nil?
  end
  
  # インスタンス変数の初期化
  def initialize_resource_variables
    @cache ||= cache_instance
    @resources ||= {}
  end

  def initialize(*args)
    initialize_resource_variables
    super
  end

  def initialize_copy(original_object)
    super
    # @resourcesがコピーされた分のカウンタを上げる
    @resources.each do |id, count|
      @cache.attach(id, count) if count > 0
    end
  end

  # 読み込んだリソースを全て解放する
  # @warning このモジュールを使ってloadした際は、最後に必ずこのメソッドを呼ぶこと
  def release_all_resources
    @resources.each {|id, count| @cache.release(id, count) }
    @resources.clear
    @cache = cache_instance
  end

  # リソースを解放する
  # @param [Fixnum] id リソースID
  def release_resource(id)
    detach_resource(id)
    @cache.release(id)
  end

  # Bitmapを読み込む
  # @return [Fixnum] リソースID
  # @param [String] filename ファイル名
  # @param [Fixnum] hue 色相
  def load_bitmap_resource(filename, hue = nil)
    id = @cache.fetch_bitmap(filename, hue||0)
    attach_resource(id)
    id
  end

  # rvdata2を読み込む
  # @return [Fixnum] リソースID
  # @param [String] filename ファイル名
  def load_rvdata2_resource(filename)
    id = @cache.fetch_rvdata2(filename)
    attach_resource(id)
    id
  end

  # @return [Object] リソースデータ
  # @return [Fixnum] リソースID
  def resource_data(id)
    @cache.raw_data(id)
  end

  # @return [Object] ロード時に使用したシグネチャ
  # @return [Fixnum] リソースID
  def resource_signature(id)
    @cache.signature(id)
  end


private
  # 参照カウンタをあげる
  def attach_resource(id)
    if @resources.has_key?(id)
      @resources[id] += 1
    else
      @resources[id] = 1
    end
  end

  # 参照カウンタをさげる
  def detach_resource(id)
    if @resources.has_key?(id) && ((@resources[id] -= 1) <= 0)
      @resources.delete(id)
    end
  end

end
