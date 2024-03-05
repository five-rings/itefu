
# lib, for the purpose of using pry
add <<-EOS, :pry
  lib/require
  lib/mutex
  lib/rubygems
  lib/pry
EOS
add <<-EOS, :benchmark
  lib/require
  lib/rubygems
  lib/benchmark
EOS

# Basics
add <<-EOS
  itefu
  itefu_build
  itefu_exception
EOS

# Win32
add <<-EOS
  win32/itefu_win32
  win32/itefu_win32_ini
  win32/itefu_win32_window
  win32/itefu_win32_hook
EOS

# Debug
add "debug/itefu_debug_define"
add <<-EOS, :debug, :release
  debug/itefu_debug
  debug/itefu_debug_log
  debug/itefu_debug_dump
  debug/itefu_debug_splittimer
EOS

# Extention
add "bitmap"

# Utilities
add <<-EOS
  utility/itefu_utility
  utility/itefu_utility_math
  utility/itefu_utility_array
  utility/itefu_utility_string
  utility/itefu_utility_time
  utility/itefu_utility_function
  utility/itefu_utility_module
  utility/itefu_utility_callback
EOS
# State
add <<-EOS
  utility/state/itefu_utility_state
  utility/state/itefu_utility_state_context
  utility/state/itefu_utility_state_donothing
  utility/state/itefu_utility_state_wait
  utility/state/itefu_utility_state_callback
  utility/state/itefu_utility_state_callback_simple
EOS

# Color
add "itefu_color"

# Tilemap
add <<-EOS
  tilemap/itefu_tilemap
  tilemap/itefu_tilemap_base
  tilemap/itefu_tilemap_redraw
  tilemap/itefu_tilemap_predraw
EOS

# Resource
add <<-EOS
  resource/itefu_resource
  resource/itefu_resource_referencecounter
  resource/itefu_resource_container
  resource/itefu_resource_cache
  resource/itefu_resource_loader
EOS

# RGSS3
add <<-EOS
  rgss3/itefu_rgss3
  rgss3/itefu_rgss3_filename
  rgss3/itefu_rgss3_rect
  rgss3/itefu_rgss3_input
  rgss3/definition/itefu_rgss3_definition
  rgss3/definition/itefu_rgss3_definition_color
  rgss3/definition/itefu_rgss3_definition_animation
  rgss3/definition/itefu_rgss3_definition_direction
  rgss3/definition/itefu_rgss3_definition_face
  rgss3/definition/itefu_rgss3_definition_tile
  rgss3/definition/itefu_rgss3_definition_icon
  rgss3/definition/itefu_rgss3_definition_messageformat
  rgss3/definition/itefu_rgss3_definition_event
  rgss3/definition/itefu_rgss3_definition_balloon
  rgss3/definition/itefu_rgss3_definition_item
  rgss3/definition/itefu_rgss3_definition_equipment
  rgss3/definition/itefu_rgss3_definition_skill
  rgss3/definition/itefu_rgss3_definition_enemy
  rgss3/definition/itefu_rgss3_definition_state
  rgss3/definition/itefu_rgss3_definition_status
  rgss3/definition/itefu_rgss3_definition_feature
  rgss3/definition/itefu_rgss3_definition_map
  rgss3/itefu_rgss3_resource
  rgss3/itefu_rgss3_resource_pool
  rgss3/itefu_rgss3_bitmap
  rgss3/itefu_rgss3_viewport
  rgss3/itefu_rgss3_sprite
  rgss3/itefu_rgss3_plane
  rgss3/itefu_rgss3_window
  rgss3/itefu_rgss3_tilemap
  rgss3/itefu_rgss3_tilemap_redraw
  rgss3/itefu_rgss3_tilemap_predraw
  rgss3/itefu_rgss3_eventinterpreter
  rgss3/itefu_rgss3_none
EOS

# Config
add <<-EOS
  config/itefu_config
EOS

# Language
add <<-EOS
  language/itefu_language
  language/itefu_language_loader
  language/itefu_language_message
EOS

# System
add <<-EOS
  system/itefu_system
  system/itefu_system_base
  system/itefu_system_manager
EOS

# Timer
add <<-EOS
  timer/itefu_timer
  timer/itefu_timer_win32
  timer/itefu_timer_base
  timer/itefu_timer_real
  timer/itefu_timer_frame
  timer/itefu_timer_performance_counter
  timer/itefu_timer_manager
EOS

# Fade
add <<-EOS
  fade/itefu_fade
  fade/itefu_fade_manager
EOS

# SaveData
add <<-EOS
  savedata/itefu_savedata
  savedata/itefu_savedata_base
  savedata/itefu_savedata_loader
EOS

# Input
add <<-EOS
  input/itefu_input
  input/itefu_input_win32
  input/itefu_input_win32_joypad
  input/itefu_input_status
  input/itefu_input_status_base
  input/itefu_input_status_win32
  input/itefu_input_status_win32_joypad
  input/itefu_input_semantics
  input/itefu_input_manager
  input/itefu_input_cursor
  input/itefu_input_dll
  input/itefu_input_command
  input/itefu_input_commander
EOS

# Sound
add <<-EOS
  sound/itefu_sound
  sound/itefu_sound_manager
  sound/itefu_sound_environment
EOS

# Database
add <<-EOS
  database/itefu_database
  database/itefu_database_loader
  database/itefu_database_table
  database/itefu_database_table_base
  database/itefu_database_table_baseitem
  database/itefu_database_table_system
EOS

# Animation
add <<-EOS
  animation/itefu_animation
  animation/itefu_animation_player
  animation/itefu_animation_base
  animation/itefu_animation_wait
  animation/itefu_animation_composite
  animation/itefu_animation_sequence
  animation/itefu_animation_keyframe
  animation/itefu_animation_battler
  animation/itefu_animation_effect
EOS

# Focus
add <<-EOS
  focus/itefu_focus
  focus/itefu_focus_focusable
  focus/itefu_focus_controller
EOS

# Unit
add <<-EOS
  unit/itefu_unit
  unit/itefu_unit_manager
  unit/itefu_unit_base
  unit/itefu_unit_composite
EOS

# SceneGraph
add <<-EOS
  scenegraph/itefu_scenegraph
  scenegraph/itefu_scenegraph_base
  scenegraph/itefu_scenegraph_rendertarget
  scenegraph/itefu_scenegraph_touchable
  scenegraph/itefu_scenegraph_root
  scenegraph/itefu_scenegraph_sprite
  scenegraph/itefu_scenegraph_node
EOS

# Layout
add <<-EOS
  layout/itefu_layout
  layout/itefu_layout_definition
  layout/itefu_layout_viewmodel
  layout/itefu_layout_keyframe
  layout/view/itefu_layout_view
EOS
add "layout/view/itefu_layout_view_debug", :debug
add <<-EOS
  layout/view/itefu_layout_view_textfile
  layout/view/itefu_layout_view_rvdata2
  layout/view/itefu_layout_view_proc
  layout/view/itefu_layout_view_effect
  layout/view/itefu_layout_view_iconcursor
  layout/observable/itefu_layout_observable
  layout/observable/itefu_layout_observable_object
  layout/observable/itefu_layout_observable_collection
  layout/control/itefu_layout_control
  layout/control/itefu_layout_control_dsl
  layout/control/itefu_layout_control_ordering
  layout/control/itefu_layout_control_bindable
  layout/control/itefu_layout_control_callback
  layout/control/itefu_layout_control_drawcontrol
  layout/control/itefu_layout_control_rendertarget
  layout/control/itefu_layout_control_drawable
  layout/control/itefu_layout_control_alignmentable
  layout/control/itefu_layout_control_orientable
  layout/control/itefu_layout_control_focusable
  layout/control/itefu_layout_control_intrusivable
  layout/control/itefu_layout_control_resource
  layout/control/itefu_layout_control_animatable
  layout/control/itefu_layout_control_font
  layout/control/itefu_layout_control_background
  layout/control/itefu_layout_control_underline
  layout/control/itefu_layout_control_base
  layout/control/itefu_layout_control_decorator
  layout/control/itefu_layout_control_importer
  layout/control/itefu_layout_control_sprite
  layout/control/itefu_layout_control_window
  layout/control/itefu_layout_control_root
EOS
add "layout/control/itefu_layout_control_root_debug", :debug
add <<-EOS
  layout/control/itefu_layout_control_separator
  layout/control/itefu_layout_control_label
  layout/control/itefu_layout_control_bitmap
  layout/control/itefu_layout_control_image
  layout/control/itefu_layout_control_face
  layout/control/itefu_layout_control_chara
  layout/control/itefu_layout_control_icon
  layout/control/itefu_layout_control_formatstring
  layout/control/itefu_layout_control_text
  layout/control/itefu_layout_control_textarea
  layout/control/itefu_layout_control_composite
  layout/control/itefu_layout_control_canvas
  layout/control/itefu_layout_control_lineup
  layout/control/itefu_layout_control_cabinet
  layout/control/itefu_layout_control_grid
  layout/control/itefu_layout_control_tile
  layout/control/itefu_layout_control_scrollable
  layout/control/itefu_layout_control_scrollbar
  layout/control/itefu_layout_control_pagable
  layout/control/itefu_layout_control_selectable
  layout/control/itefu_layout_control_selector
  layout/control/itefu_layout_control_selectdelegation
  layout/control/itefu_layout_control_cursor
  layout/control/itefu_layout_control_dial
EOS

add <<-EOS
  BehaviorTree/itefu_behaviortree
  BehaviorTree/itefu_behaviortree_manager
  BehaviorTree/itefu_behaviortree_common
  BehaviorTree/Node/itefu_behaviortree_node
  BehaviorTree/Node/itefu_behaviortree_node_base
  BehaviorTree/Node/itefu_behaviortree_node_decorator
  BehaviorTree/Node/itefu_behaviortree_node_conditional
  BehaviorTree/Node/itefu_behaviortree_node_inverter
  BehaviorTree/Node/itefu_behaviortree_node_succeeder
  BehaviorTree/Node/itefu_behaviortree_node_untilfail
  BehaviorTree/Node/itefu_behaviortree_node_repeater
  BehaviorTree/Node/itefu_behaviortree_node_weight
  BehaviorTree/Node/itefu_behaviortree_node_lazy
  BehaviorTree/Node/itefu_behaviortree_node_initializer
  BehaviorTree/Node/itefu_behaviortree_node_composite
  BehaviorTree/Node/itefu_behaviortree_node_sequence
  BehaviorTree/Node/itefu_behaviortree_node_selector
  BehaviorTree/Node/itefu_behaviortree_node_random
  BehaviorTree/Node/itefu_behaviortree_node_leaf
  BehaviorTree/Node/itefu_behaviortree_node_action
  BehaviorTree/Node/itefu_behaviortree_node_adhocaction
  BehaviorTree/Node/itefu_behaviortree_node_importerbase
  BehaviorTree/Node/itefu_behaviortree_node_root
EOS

# Background Loader
add <<-EOS
  backgroundloader/itefu_backgroundloader
  backgroundloader/itefu_backgroundloader_manager
  backgroundloader/itefu_backgroundloader_resourceloader
EOS

# Performance Analyzer
add <<-EOS, :debug
  debug/performance/itefu_debug_performance
  debug/performance/itefu_debug_performance_counter
  debug/performance/itefu_debug_performance_manager
EOS

# Scene
add <<-EOS
  scene/itefu_scene
  scene/itefu_scene_base
  scene/itefu_scene_manager
  scene/itefu_scene_wait
EOS
add <<-EOS, :debug
  scene/itefu_scene_debugmenu
  scene/itefu_scene_debugroot
EOS

# Aspect (for Debug)
add "aspect/itefu_aspect", :debug, :test
add <<-EOS, :debug
  aspect/itefu_aspect_profiler
EOS

# Benchmark
add <<-EOS, :benchmark
  benchmark/itefu_benchmark
  benchmark/itefu_benchmark_ruby
  benchmark/itefu_benchmark_utility
EOS

# UnitTest
add <<-EOS, :test
  unittest/itefu_unittest
  unittest/itefu_unittest_runner
  unittest/itefu_unittest_report
  unittest/itefu_unittest_assertion
  unittest/itefu_unittest_testcase
EOS

# TestCase
add <<-EOS, :test
  test/itefu_test
  test/itefu_test_unittest
  test/itefu_test_utility
  test/itefu_test_resource
  test/itefu_test_rgss3
  test/itefu_test_config
  test/itefu_test_savedata
  test/itefu_test_state
  test/itefu_test_system
  test/itefu_test_timer
  test/itefu_test_scene
  test/itefu_test_input
  test/itefu_test_database
  test/itefu_test_language
  test/itefu_test_unit
  test/itefu_test_scenegraph
  test/itefu_test_animation
  test/itefu_test_sound
  test/itefu_test_focus
  test/itefu_test_layout
  test/itefu_test_behaviortree
  test/itefu_test_aspect
EOS

# TestScene
add <<-EOS, :debug
  testscene/itefu_testscene
  testscene/itefu_testscene_filer
  testscene/sandbox/itefu_testscene_sandbox
  testscene/sandbox/itefu_testscene_sandbox_sprite
  testscene/sandbox/itefu_testscene_sandbox_window
  testscene/scenegraph/itefu_testscene_scenegraph
  testscene/scenegraph/itefu_testscene_scenegraph_sprite
  testscene/scenegraph/itefu_testscene_scenegraph_hittest
  testscene/animation/itefu_testscene_animation
  testscene/animation/itefu_testscene_animation_keyframe
  testscene/animation/itefu_testscene_animation_effect
  testscene/animation/itefu_testscene_animation_composite
  testscene/sound/itefu_testscene_sound
  testscene/sound/itefu_testscene_sound_se
  testscene/sound/itefu_testscene_sound_me
  testscene/sound/itefu_testscene_sound_bgm
  testscene/sound/itefu_testscene_sound_bgs
  testscene/sound/itefu_testscene_sound_system
  testscene/sound/itefu_testscene_sound_environment
  testscene/layout/itefu_testscene_layout
  testscene/layout/itefu_testscene_layout_list
  testscene/layout/itefu_testscene_layout_preview
  testscene/tilemap/itefu_testscene_tilemap
  testscene/tilemap/itefu_testscene_tilemap_base
  testscene/tilemap/itefu_testscene_tilemap_default
  testscene/tilemap/itefu_testscene_tilemap_redraw
  testscene/tilemap/itefu_testscene_tilemap_predraw
  testscene/itefu_testscene_menu
EOS

# Application
add "itefu_application"
