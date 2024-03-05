=begin
  Layout/与えられたパスにあるファイルを一覧し選択する
=end
class Itefu::TestScene::Layout::List < Itefu::TestScene::Filer
  def caption
    "Layout #{@name}"
  end
  
  def preview_klass
    Itefu::TestScene::Layout::Preview
  end
end
