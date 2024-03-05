=begin
  ゲーム中に変化しない定義データを読み込むクラス関連
=end
module Itefu::Database
  @@instance = nil

  # @return [Database::Loader]
  def self.instance
    @@instance
  end

  # Database::Loaderのインスタンスを生成する
  # @return [Database::Loader]
  def self.create(klass, *args)
    unload_all_tables
    @@instance = klass.new(*args)
  end

  # RGSS3のデフォルトで用意されているファイルを読み込む
  # @return [Database::Loader]
  def self.load_rgss3_tables
    return unless database = instance
    load_system_table(database)
    load_actors_table(database)
    load_classes_table(database)
    load_items_table(database)
    load_weapons_table(database)
    load_armors_table(database)
    load_skills_table(database)
    load_common_events_table(database)
    load_troops_table(database)
    load_enemies_table(database)
    load_map_infos_table(database)
    load_animations_table(database)
    load_states_table(database)
    database
  end
  
  # Database::Loaderのunload_all_tablesを呼ぶ
  def self.unload_all_tables
    return unless database = instance
    database.unload_all_db_tables
  end
  
  # Database::Loaderのdb_tableを呼ぶ
  # @return [Table::Base]
  def self.table(id)
    return unless database = instance
    database.db_table(id)
  rescue NoMethodError
    nil
  end
  
  module Default
    def load_rgss3_table(database, id, file_id, type)
#ifdef :ITEFU_DEVELOP
      if $BTEST
        file = Itefu::Rgss3::Filename::Data::BattleTest.const_get(file_id)
        unless File.file?(file)
          file = Itefu::Rgss3::Filename::Data.const_get(file_id)
        end
      else
#endif
        file = Itefu::Rgss3::Filename::Data.const_get(file_id)
#ifdef :ITEFU_DEVELOP
      end
#endif
      database.load_db_table(id, file, type)
    end

    def load_system_table(database)
      load_rgss3_table(database, :system, :SYSTEM, Itefu::Database::Table::System)
    end
    
    def load_actors_table(database)
      load_rgss3_table(database, :actors, :ACTORS, Itefu::Database::Table::BaseItem)
    end
    
    def load_classes_table(database)
      load_rgss3_table(database, :classes, :CLASSES, Itefu::Database::Table::BaseItem)
    end
    
    def load_items_table(database)
      load_rgss3_table(database, :items, :ITEMS, Itefu::Database::Table::BaseItem)
    end
    
    def load_weapons_table(database)
      load_rgss3_table(database, :weapons, :WEAPONS, Itefu::Database::Table::BaseItem)
    end
    
    def load_armors_table(database)
      load_rgss3_table(database, :armors, :ARMORS, Itefu::Database::Table::BaseItem)
    end
    
    def load_skills_table(database)
      load_rgss3_table(database, :skills, :SKILLS, Itefu::Database::Table::BaseItem)
    end
    
    def load_common_events_table(database)
      load_rgss3_table(database, :common_events, :COMMON_EVENTS, Itefu::Database::Table::Base)
    end

    def load_troops_table(database)
      load_rgss3_table(database, :troops, :TROOPS, Itefu::Database::Table::Base)
    end

    def load_enemies_table(database)
      load_rgss3_table(database, :enemies, :ENEMIES, Itefu::Database::Table::BaseItem)
    end

    def load_animations_table(database)
      load_rgss3_table(database, :animations, :ANIMATIONS, Itefu::Database::Table::Base)
    end

    def load_states_table(database)
      load_rgss3_table(database, :states, :STATES, Itefu::Database::Table::BaseItem)
    end

    def load_map_infos_table(database)
      database.load_db_table(:map_infos, Itefu::Rgss3::Filename::Data::MAP_INFOS)
    end
  end
  extend Default
  
end
