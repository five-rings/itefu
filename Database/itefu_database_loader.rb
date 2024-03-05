=begin
  データベースに定義データを読み込むクラス
=end
class Itefu::Database::Loader
  attr_reader :db_tables  # [Hash<Symbol, Database::Base>] 読み込んだデータ(テーブル)
  
  def initialize(*args)
    @db_tables = {}
    super
  end

  # @return [Boolean] 指定した識別子で読み込んでいるか
  # @param [Symbol] id 識別子
  def db_table_loaded?(id)
    @db_tables.has_key?(id)
  end
 
  # テーブルを読み込む
  # @param [Symbol] id 識別子
  # @param [String] path 読み込むテーブルのパス
  # @param [Class] klass 生成するテーブルクラス
  # @raise [ArgumentError] 既に登録されているidに再登録しようとした際に送出される
  # @return [Table::Base] 新しく生成したテーブルのインスタンス
  def load_db_table(id, path, klass = Itefu::Database::Table::Base, *args, &block)
    raise ArgumentError if db_table_loaded?(id)
    instance = klass.new(*args, &block)
    if instance.load(path)
      eval(<<-"EOS", binding, Itefu::Utility::String.script_name(__FILE__), __LINE__)
        def self.#{id.to_s}()
          db_table(:#{id.to_s})
        end
      EOS
      @db_tables[id] = instance
    end
  end

  # 読み込んだテーブルを解放する
  # @param [Symbol] id 識別子
  # @raise [ArgumentError] 登録していないidにし対して解放しようとした際に送出される
  # @return [Table::Base] 解放したテーブルのインスタンス
  def unload_db_table(id)
    raise ArgumentError unless db_table_loaded?(id)
    table = @db_tables.delete(id)
    table.unload if table
    table
  end

  # 読み込んだテーブルを全て解放する  
  def unload_all_db_tables
    @db_tables.each_value(&:unload)
    @db_tables.clear
  end

  # 読み込んだテーブルにアクセスする
  # @return [Table::Base] 街頭するテーブルのインスタンス
  # @param [Symbol] id 取得したいテーブルの識別子
  # @raise [NoMethodError] 読み込んでいないテーブルを取得しようとした
  def db_table(id)
    ITEFU_DEBUG_ASSERT(db_table_loaded?(id), "undefined method `#{id.to_s}' for #{self}", NoMethodError)
    @db_tables[id]
  end

end
