=begin
  エントリを一覧して選択したものをプレビューする画面を簡単に実装するためのクラス
=end
class Itefu::TestScene::Filer < Itefu::Scene::DebugMenu

  def preview_klass; raise Itefu::Exception::NotImplemented; end
  def caption; "#{self.class.name} #{@name}"; end
  
  def on_initialize(path, name = "", dir_level = 0, base_path = nil)
    if dir_level == 0 && base_path.nil?
      @path = ""
      @base_path = path
    else
      @path = path
      @base_path = base_path
    end
    @name = name
    @dir_level = dir_level
  end
  
  # システムメニューを追加する
  def add_system_menu(m)
    m.add_item("Back", :back)
  end
  
  # フォルダ/ファイルをメニューに追加する
  def add_entries_to_menu(m)
    entries = Dir.entries(current_path)
    count = m.items.size

    # フォルダの追加
    entries.each do |entry|
      next if entry == '.' || entry == '..'
      next unless File.directory? full_path(entry) rescue next
      m.add_item("#{entry}/", entry)
    end

    # フォルダがあったときだけセパレータを追加する
    m.add_separator if m.items.size > count

    # ファイルの追加
    entries.each do |entry|
      next if entry == '.' || entry == '..'
      next if File.directory? full_path(entry) rescue next
      next if filtered_entry?(entry)
      m.add_item(entry_name(entry), entry)
    end
  end
  
  # @return [Boolean] エントリをリストから除外するか
  def filtered_entry?(entry)
    false
  end
  
  # @return [String] エントリの表示名
  def entry_name(entry)
    File.basename(entry, ".*")
  end

  def menu_list(m)
    add_system_menu(m)
    m.add_separator
    add_entries_to_menu(m)
  end
 
  def full_path(entry)
    "#{current_path}/#{entry}"
  end
  
  def current_path
    "#{@base_path}/#{@path}"
  end
  
  def top_directory?
    @dir_level == 0
  end

  def on_item_selected(index, data)
    case data
    when :back
      quit
    else
      if File.directory? full_path(data)
        on_directory_selected(data)
      else
        on_file_selected(data)
      end
    end
  end
  
  def on_directory_selected(data)
    path_to_data = "#{@path}/#{data}"
    switch_scene(self.class, path_to_data, "#{@name}/#{data}", @dir_level + 1, @base_path)
  end
  
  def on_file_selected(data)
    path_to_data = "#{@path}/#{data}"
    switch_scene(preview_klass, @base_path, path_to_data)
  end
  
end
