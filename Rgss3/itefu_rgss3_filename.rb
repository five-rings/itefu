=begin
  ツクールの仕様で決められているファイルパス
=end
# @note _sや_nは書式付文字列であることをあらわす.
#       _s: 文字列
#       _n: 数値
module Itefu::Rgss3::Filename

  module Graphics
    WINDOWSKIN    = "Graphics/System/Window"
    ICONSET       = "Graphics/System/IconSet"
    FACES_s       = "Graphics/Faces/%s"
    TILESETS_s    = "Graphics/Tilesets/%s"
    CHARACTERS_s  = "Graphics/Characters/%s"
    BALLOON       = "Graphics/System/Balloon"
    BATTLE_START  = "Graphics/System/BattleStart"
    ANIMATIONS_s  = "Graphics/Animations/%s"
    PARALLAXES_s  = "Graphics/parallaxes/%s"
    PICTURES_s    = "Graphics/Pictures/%s"
    FLOOR_s       = "Graphics/BattleBacks1/%s"
    WALL_s        = "Graphics/BattleBacks2/%s"
    BATTLER_s     = "Graphics/Battlers/%s"
  end

  module Data
    MAP_n         = "Data/Map%03d.rvdata2"
    ACTORS        = "Data/Actors.rvdata2"
    CLASSES       = "Data/Classes.rvdata2"
    SKILLS        = "Data/Skills.rvdata2"
    ITEMS         = "Data/Items.rvdata2"
    WEAPONS       = "Data/Weapons.rvdata2"
    ARMORS        = "Data/Armors.rvdata2"
    ENEMIES       = "Data/Enemies.rvdata2"
    TROOPS        = "Data/Troops.rvdata2"
    STATES        = "Data/States.rvdata2"
    ANIMATIONS    = "Data/Animations.rvdata2"
    TILESETS      = "Data/Tilesets.rvdata2"
    COMMON_EVENTS = "Data/CommonEvents.rvdata2"
    SYSTEM        = "Data/System.rvdata2"
    MAP_INFOS     = "Data/MapInfos.rvdata2"

    module BattleTest
      ACTORS        = "Data/BT_Actors.rvdata2"
      CLASSES       = "Data/BT_Classes.rvdata2"
      SKILLS        = "Data/BT_Skills.rvdata2"
      ITEMS         = "Data/BT_Items.rvdata2"
      WEAPONS       = "Data/BT_Weapons.rvdata2"
      ARMORS        = "Data/BT_Armors.rvdata2"
      ENEMIES       = "Data/BT_Enemies.rvdata2"
      TROOPS        = "Data/BT_Troops.rvdata2"
      STATES        = "Data/BT_States.rvdata2"
      ANIMATIONS    = "Data/BT_Animations.rvdata2"
      TILESETS      = "Data/BT_Tilesets.rvdata2"
      COMMON_EVENTS = "Data/BT_CommonEvents.rvdata2"
      SYSTEM        = "Data/BT_System.rvdata2"
    end
  end
  
  module Audio
    BGM_s         = "Audio/BGM/%s"
    BGS_s         = "Audio/BGS/%s"
    ME_s          = "Audio/ME/%s"
    SE_s          = "Audio/SE/%s"
  end

  MOVIES_s = "Movies/%s"

end
