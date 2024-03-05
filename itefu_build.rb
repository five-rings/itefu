=begin
  ビルド設定
=end

#ifdef :debug
#define :ITEFU_DEBUG
#define :ITEFU_DEVELOP
#else_ifdef :release
#define :ITEFU_RELEASE
#else
#define :ITEFU_MASTER
#endif

#ifdef :pry
#define :ITEFU_BINDING_PRY, "Kernel.binding.pry"
#else
#define :ITEFU_BINDING_PRY, :NOP_LINE
#endif

module Itefu::Build

  # ビルドターゲット
  module Target
    MASTER  = :master     # 製品版
    RELEASE = :release    # 開発用機能なし版
    DEVELOP = :develop    # 開発版
  end

  @@build_target = Target::MASTER

  # ビルドターゲットを設定する
  def self.target=(target)
    @@build_target = target
  end

  # ビルドターゲットの取得
  def self.target
    @@build_target
  end

end

