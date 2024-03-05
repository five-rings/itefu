=begin
  イベントを実行する
=end

#ifdef :ITEFU_DEVELOP
#define :ITEFU_DEBUG_DUMP_EVENT_INFO, "dump_event_info"
#else
#define :ITEFU_DEBUG_DUMP_EVENT_INFO, :NOP_LINE
#endif

module Itefu::Rgss3::EventInterpreter
  attr_reader :event_status     # [EventStatus] 実行状態
  attr_reader :event_finished   # [Proc] 処理終了時に呼ばれる
  
  module EventCode
    include Itefu::Rgss3::Definition::Event::Code
  end
  
  NEW_LINE = Itefu::Rgss3::Definition::MessageFormat::NEW_LINE

  # イベントの実行状態
  class EventStatus
    attr_reader :map_id, :event_id, :page_index
    attr_reader :eventcommands
    attr_reader :context    # [Object] 任意のオブジェクト
    attr_accessor :program_counter
    attr_reader :data       # [Hash] 保存の必要がある各種データ

    def initialize
      @data = {}
      reset
    end

    # 初期化する
    def reset(map_id = nil, event_id = nil, page_index = nil, eventcommands = nil, context = nil)
      @map_id = map_id
      @event_id = event_id
      @page_index = page_index
      @eventcommands = eventcommands
      @context = context
      @program_counter = 0
      @data.clear
    end

    # 擬似乱数生成機を設定する
    def reset_random(seed)
      @data[:random] = Random.new(seed)
    end

    # 現在のマップID
    def current_map_id
      # @note map_idはイベントを起動したマップなのでマップ移動を挟むイベントの場合には現在のマップとはズレてしまう
      @data[:map_id] || @map_id
    end

    # 他のオブジェクトからディープコピーする
    # @warning eventcommandsは書き換えないだろうという前提で参照コピーしている
    def copy(status)
      return reset unless status
      @map_id = status.map_id
      @event_id = status.event_id
      @page_index = status.page_index
      @eventcommands = status.eventcommands
      @context = status.context
      @program_counter = status.program_counter
      # @hack merge!の方が遅い
      @data.clear
      status.data.each do |key, value|
        @data[key] = value
      end
      @data[:random] = @data[:random] && @data[:random].clone
    end

    # contextにdef []が指定されている場合の値を取得する
    def option(key)
      context && context[key]
    rescue
      nil
    end
  end

  def initialize(parent = nil, *args)
    @event_status = EventStatus.new
    @parent = parent if parent
    super
  end

  # イベントの処理を開始する
  # @param [Fixnum] map_id マップの識別子
  # @param [Fixnum] event_id マップ内のイベントの識別子
  # @param [Fixnum] page_index イベント内のページ番号
  # @param [RPG::EventCommand] イベントのコマンド
  # @param [Object] context 任意のオブジェクト
  # @param [Proc] finished イベントの処理が終わった際に呼ばれるproc
  # @return [EventInterpreter] レシーバーを返す
  def start_event(map_id, event_id, page_index, eventcommands, context = nil, finished = nil)
    @event_status.reset(map_id, event_id, page_index, eventcommands, context)
    @event_finished = finished if finished
    run_event
    self
  end

  # イベントの処理を再開する
  # @param [Object] context 任意のオブジェクト
  # @param [EventStatus] status 再開したい状態を保持したEventStatus
  # @param [Proc] finished イベントの処理が終わった際に呼ばれるproc
  # @return [EventInterpreter] レシーバーを返す
  def resume_event(status, finished = nil)
    @event_status.copy(status)
    @event_finished = finished if finished
    run_event
    self
  end

  # @return [Boolean] イベントの処理中か
  def event_interpreter_running?
    @event_fiber.nil?.!
  end

  # このフレームでのイベント処理を進める
  def update_event_interpreter
    @event_fiber.resume if @event_fiber
  end


private

  # イベントの処理を実行する
  def run_event
    @event_fiber = Fiber.new {
      event_interpreter
      @event_fiber = nil
      @event_finished.call(self, @event_status) if @event_finished
      @event_status.reset
    }
  end

  # イベントを処理する
  def event_interpreter
    while (command = current_command)
      execute_command(command)
      step_to_next_command
    end

    # メッセージが閉じるのを待つ
    event_wait_for_message_closing
    # 他のイベントのウィンドウと繋がらないように1f待つ
    # 子イベントの場合は親イベントと繋がるように待たない
    event_wait unless @parent
  end

  # 現在のコマンドを得る
  def current_command
    event_status.eventcommands[event_status.program_counter]
  end

  # 次のコマンドを得る
  def next_command
    event_status.eventcommands[event_status.program_counter + 1]
  end
  
  # 次のコマンドへ進む
  def step_to_next_command
    event_status.program_counter += 1
  end
  
  # 前にコマンドに戻る
  def back_to_previous_command
    event_status.program_counter -= 1
  end

  # 指定したインデント数になるまでイベントをスキップする
  def skip_command(indent)
    step_to_next_command while next_command.indent > indent
  end
  
  # 指定したインデント数になるまでイベントを巻き戻す
  def rewind_command(indent)
    begin
      back_to_previous_command
    end until current_command.indent == indent
  end

  # 指定したコマンドを探す
  def find_command(start = 0)
    event_status.program_counter = start
    step_to_next_command until (c = current_command).nil? || (yield c)
  end
  
  # イベントの処理を中断する
  def abort_command
    event_status.program_counter = event_status.eventcommands.size
  end
  
  # コンディションをメモし分岐する
  def branch(indent, result)
    event_status.data[indent] = result
  end
  
  # 最後に分岐した際のコンディションを得る
  def branch_result(indent)
    event_status.data[indent]
  end

  # コマンドを実行する
  def execute_command(command)
    send_command(command.code, command.indent, command.parameters)
 end
  
  # コマンドに対応したメソッドを呼び出す
  def send_command(name, *args)
    event_wait_by_command(name)

    command_method = :"command_#{name}"
    if respond_to?(command_method, true)
      send(command_method, *args)
    else
      ITEFU_DEBUG_OUTPUT_CAUTION("#{command_method} is not found in #{self.class}")
      ITEFU_DEBUG_DUMP_EVENT_INFO
    end
  end
  
  # イベントの処理をせずに、指定したフレーム数だけ待機する
  def event_wait(count = 1)
    count.times { Fiber.yield }
  end
  
  # @return [Integer] 擬似乱数を返す
  def event_rand(*args)
    (@event_status.data[:random] || Random).rand(*args)
  end
  
  # コマンドを処理しはじめる前のウェイト
  # @note デフォルトでメッセージ表示中は待機するが、event_wait_#{name}というメソッドを作って上書きできる
  def event_wait_by_command(name)
    wait_method = :"event_wait_#{name}"
    if respond_to?(wait_method, true)
      send(wait_method)
    else
      event_wait_for_message_closing
    end
  end

  def event_wait_for_message_closing
    event_wait while event_message_showing?
  end
  
  
#ifdef :ITEFU_DEVELOP
  # イベントの情報を出力する
  def dump_event_info
    ITEFU_DEBUG_OUTPUT_CAUTION("Event: map.#{@event_status.map_id}, ev.#{@event_status.event_id}, p.#{@event_status.page_index}, l.#{@event_status.program_counter}")
  end
#endif


  # --------------------------------------------------
  # コマンドが使用している型
  
  # ショップの品目
  # @param [Fixnum] item_type 0:アイテム, 1:武器, 2:防具
  EventShopItem = Struct.new(:item_type, :id, :price)


  # --------------------------------------------------
  # コマンドのデフォルト実装

  # 処理する必要のないイベント
  def command_0(indent, params); end    # 空白
  def event_wait_0; end
  def command_112(indent, params); end  # ループ
  def event_wait_112; end
  def command_118(indent, params); end  # ラベル
  def event_wait_118; end
  def command_404(indent, params); end  # 選択肢を表示の分岐終了
  def event_wait_404; end
  def command_412(indent, params); end  # 条件判断の分岐終了
  def event_wait_412; end
  def command_505(indent, params); end  # 移動ルートのエディタ上の表示のためのダミー
  def command_604(indent, params); end  # バトルの分岐終了
  def event_wait_604; end
 
   # メッセージの表示
  def command_101(indent, params)
    message = ""
    while next_command.code == EventCode::MESSAGE_SEQUEL
      step_to_next_command
      message << current_command.parameters[0]
      message << NEW_LINE
    end

    event_show_message(message, params[0], params[1], params[2], params[3])
  end
  
  # メッセージの表示（継続）
  def command_401(indent, params)
    # @note 通常は101でまとめて処理されるので呼ばれることはない
  end
  def event_wait_401; end

  # 選択肢の表示
  def command_102(indent, params)
    event_show_choices(params[0], params[1] - 1)
    event_wait while event_choices_showing?
  end
  def event_wait_102; end  # メッセージウィンドウに重ねて表示できる

  # 数値入力
  def command_103(indent, params)
    event_show_numeric_input(params[0], params[1])
    event_wait while event_numeric_input_showing?
  end
  def event_wait_103; end  # メッセージウィンドウに重ねて表示できる

  # アイテム選択
  def command_104(indent, params)
    event_show_item_select(params[0])
    event_wait while event_item_select_showing?
  end
  def event_wait_104; end  # メッセージウィンドウに重ねて表示できる

  # スクロール文章の表示
  def command_105(indent, params)
    event_wait until event_message_closed?

    text = ""
    while next_command.code == EventCode::SCROLLING_TEXT_SEQUEL
      step_to_next_command
      text << current_command.parameters[0]
      text << NEW_LINE
    end

    event_show_scrolling_text(text, params[0], params[1])
    event_wait while event_scrolling_text_showing?
  end

  # 注釈
  # @note :ではじまる注釈があれば特殊コマンドと解釈し、対応するメソッドを呼び出そうとする
  def command_108(indent, params)
    comment = params[0]
    begin
      excmd, exarg = Itefu::Utility::String.parse_note_command(comment)
      if excmd
        args = exarg && exarg.split(",")
        send_command(excmd, *args)
      end

      # next command
      break unless next_command.code == EventCode::COMMENT_SEQUEL
      step_to_next_command
      comment = current_command.parameters[0]
    end while true # next == COMMENT_SEQUEL
  end
  def event_wait_108; end   # 個別に対応する

  def command_408(indent, params)
    command_108(indent, params)
  end
  def event_wait_408; end 

  # 条件分岐
  def command_111(indent, params)
    result = conditional_branch(indent, params)
    branch(indent, result)
    skip_command(indent) unless result
  end
  def event_wait_111; end   # メッセージ表示中でも無視して進める

  # ループの中断
  def command_113(indent, params)
    # ループ終端がくるまでコマンドをスキップする
    begin
      step_to_next_command
    end until current_command.nil? ||
              ( current_command.code == EventCode::LOOP_END &&
                current_command.indent < indent)
  end
  def event_wait_113; end   # メッセージ表示中でも無視して進める

  # イベント処理の中断
  def command_115(indent, params)
    abort_command
  end

   # コモンイベント
  def command_117(indent, params)
    id = params[0]
    if cev = common_event(id)
      child = self.class.new(self)
      if @event_status.data.has_key?(:child)
        child.resume_event(@event_status.data[:child], method(:common_event_finished))
      else
        eid = @event_status.event_id
        child.start_event(@event_status.map_id, eid, id, cev.list, nil, method(:common_event_finished))
      end
      @event_status.data[:child] = child.event_status
      child.update_event_interpreter
      # 中断状態なら親も中断して次フレームに再開する
      while child.event_interpreter_running?
        event_wait
        child.update_event_interpreter
      end
    else
      ITEFU_DEBUG_OUTPUT_CAUTION "CommonEvent#{id} is not found"
      ITEFU_DEBUG_DUMP_EVENT_INFO
    end
    @event_status.data.delete(:child)
  end
  def event_wait_117; end

  # ラベルジャンプ
  def command_119(indent, params)
    pc = event_status.program_counter
    label_name = params[0]
    find_command {|command| command.code == EventCode::LABEL && command.parameters[0] == label_name }

    if current_command
      # ラベルを見つけたので、次のコマンド処理で目的のラベルが処理されるようにする
      back_to_previous_command
    else
      # 指定したラベルが存在しなかったので、何もしなかったことにする
      event_status.program_counter = pc
    end
  end
  def event_wait_119; end   # メッセージ表示中でも無視して進める

 # スイッチの操作
  def command_121(indent, params)
    value = (params[2] == 0)
    (params[0]..params[1]).each do |id|
      change_switch(id, value)
    end
  end
  def event_wait_121; end

  # 変数の操作  
  def command_122(indent, params)
    value = case params[3]
            when 0  # 定数
              params[4]
            when 1  # 変数
              variable(params[4])
            when 2  # 乱数
              params[4] + event_rand(params[5] - params[4] + 1)
            when 3  # ゲームデータ
              game_data_operand(params[4], params[5], params[6])
            when 4  # スクリプト
              begin
                self.instance_eval(params[4])
              rescue => e
                ITEFU_DEBUG_OUTPUT_ERROR "Invalid Event Script: #{e.inspect}"
                ITEFU_DEBUG_DUMP_EVENT_INFO
                0
              end
            else
              raise Itefu::Exception::Unreachable
            end
    (params[0]..params[1]).each do |id|
      operate_variable(id, params[2], value)
    end
  end
  def event_wait_122; end

  # セルフスイッチの操作
  def command_123(indent, params)
    if @event_status.map_id && @event_status.event_id
      change_self_switch(@event_status.map_id, @event_status.event_id, params[0], (params[1] == 0))
    else
      ITEFU_DEBUG_OUTPUT_CAUTION("Failed to change a self-switch because map id and/or event id is nil")
      ITEFU_DEBUG_DUMP_EVENT_INFO
    end
  end
  def event_wait_123; end
  
  # タイマーの操作  
  def command_124(indent, params)
    if params[0] == 0
      event_start_timer(params[1])
    else
      event_stop_timer
    end
  end

  # 所持金の増減
  def command_125(indent, params)
    event_add_money operated_value(params[0], params[1], params[2])
  end

  # アイテムの増減
  def command_126(indent, params)
    event_add_item params[0], operated_value(params[1], params[2], params[3])
  end

  # 武器の増減
  def command_127(indent, params)
    event_add_weapon params[0], operated_value(params[1], params[2], params[3]), params[4]
  end

  # 防具の増減
  def command_128(indent, params)
    event_add_armor params[0], operated_value(params[1], params[2], params[3]), params[4]
  end
   
  # メンバーの入れ替え
  def command_129(indent, params)
    if params[1] == 0
      event_join_party(params[0], params[2] == 1)
    else
      event_leave_party(params[0])
    end
  end 

  # 戦闘 BGM の変更
  def command_132(indent, params)
    event_change_battle_bgm(params[0])
  end

  # 戦闘終了 ME の変更
  def command_133(indent, params)
    event_change_battle_me(params[0])
  end

  # セーブ禁止の変更
  def command_134(indent, params)
    event_change_save_prohibition(params[0] == 0)
  end

   # メニュー禁止の変更
  def command_135(indent, params)
    event_change_menu_prohibition(params[0] == 0)
  end
  
  # エンカウント禁止の変更
  def command_136(indent, params)
    event_change_encounter_prohibition(params[0] == 0)
  end 

  # 並び替え禁止の変更
  def command_137(indent, params)
    event_change_formation_prohibition(params[0] == 0)
  end

  # 場所の移動
  def command_201(indent, params)
    event_wait until event_message_closed?
    event_wait while event_player_moving?

    if params[0] == 0
      map_id = params[1]
      x = params[2]
      y = params[3]
    else
      map_id = variable(params[1])
      x = variable(params[2])
      y = variable(params[3])
    end
    event_move_player(map_id, x, y, params[4], params[5])
    event_wait while event_player_moving?
  end

  # 乗り物の位置設定
  def command_202(indent, params)
    if params[1] == 0
      map_id = params[2]
      x = params[3]
      y = params[4]
    else
      map_id = variable(params[2])
      x = variable(params[3])
      y = variable(params[4])
    end
    event_move_vehicle(params[0], map_id, x, y)
    event_wait while event_vehicle_moving?(params[0])
  end

  # イベントの位置設定
  def command_203(indent, params)
    subject = mapobject(params[0])
    case params[1]
    when 0
      event_move_event(subject, params[2], params[3], params[4])
    when 1
      event_move_event(subject, variable(params[2]), variable(params[3]), params[4])
    else
      event_swap_event(subject, mapobject(params[2]), params[4])
    end
    event_wait while event_event_moving?(subject)
  end

  # マップのスクロール
  def command_204(indent, params)
    event_wait while event_scrolling?
    event_scroll(params[0], params[1], params[2])
  end

  # 移動ルートの設定
  def command_205(indent, params)
    subject = mapobject(params[0])
    object = mapobject(Itefu::Rgss3::Definition::Event::Id.player?(params[0]) ? Itefu::Rgss3::Definition::Event::Id::THIS_EVENT : Itefu::Rgss3::Definition::Event::Id::PLAYER) rescue nil
    event_assign_route(subject, params[1], object)
    event_wait while event_routing?(subject) if params[1].wait
  end

  # 乗り物の乗降
  def command_206(indent, params)
    event_get_vehicle_on_off
  end

  # 透明状態の変更
  def command_211(indent, params)
    event_change_transparency(params[0] == 0)
  end
  
  # アニメーションの表示
  def command_212(indent, params)
    subject = mapobject(params[0])
    event_play_effect_animation(subject, params[1])
    event_wait while event_effect_animation_playing?(subject) if params[2]
  end
    
  # フキダシアイコンの表示
  def command_213(indent, params)
    subject = mapobject(params[0])
    event_show_balloon(subject, params[1])
    event_wait while event_balloon_showing?(subject) if params[2]
  end

  # イベントの一時消去
  def command_214(indent, params)
    event_disable_this_event
  end

  # 隊列歩行の変更
  def command_216(indent, params)
    event_change_if_show_followers(params[0] == 0)
  end

  # 隊列メンバーの集合
  def command_217(indent, params)
    event_gather_followers
    event_wait while event_gathering_followers?
  end

  # 画面のフェードアウト
  def command_221(indent, params)
    event_wait until event_message_closed?

    event_fade_out
    event_wait while event_fading_out?
  end

  # 画面のフェードイン
  def command_222(indent, params)
    event_wait until event_message_closed?

    event_fade_in
    event_wait while event_fading_in?
  end

  # 画面の色調変更
  def command_223(indent, params)
    event_change_tone(params[0], params[1])
    event_wait(params[1]) if params[2]
  end

  # 画面のフラッシュ
  def command_224(indent, params)
    event_flash(params[0], params[1])
    event_wait(params[1]) if params[2]
  end

  # 画面のシェイク
  def command_225(indent, params)
    event_shake(params[0], params[1], params[2])
    event_wait(params[2]) if params[3]
  end

  # ウェイト
  def command_230(indent, params)
    event_wait(params[0])
  end
 
  # ピクチャの表示
  def command_231(indent, params)
    if params[3] == 0
      x = params[4]
      y = params[5]
    else
      x = variable(params[4])
      y = variable(params[5])
    end
    event_show_picture(params[0], params[1], params[2], x, y, params[6]/100.0, params[7]/100.0, params[8], params[9])
  end

  # ピクチャの移動
  def command_232(indent, params)
     if params[3] == 0
      x = params[4]
      y = params[5]
    else
      x = variable(params[4])
      y = variable(params[5])
    end
    event_move_picture(params[0], params[2], x, y, params[6]/100.0, params[7]/100.0, params[8], params[9], params[10])
    event_wait(params[10]) if params[11]
  end

  # ピクチャの回転
  def command_233(indent, params)
    event_rotate_picture(params[0], params[1])
  end
  
  # ピクチャの色調変更
  def command_234(indent, params)
    event_change_picture_tone(params[0], params[1], params[2])
    event_wait(params[2]) if params[3]
  end

  # ピクチャの消去
  def command_235(indent, params)
    event_erase_picture(params[0])
  end

  # 天候の設定
  def command_236(indent, params)
    event_change_weather(params[0], params[1], params[2])
    event_wait(params[2]) if params[3]
  end

  # BGM の演奏
  def command_241(indent, params)
    event_play_bgm(params[0])
  end

  # BGM のフェードアウト
  def command_242(indent, params)
    event_stop_bgm(params[0] * 1000)
  end

  # BGM の保存
  def command_243(indent, params)
    event_cache_bgm
  end

  # BGM の再開
  def command_244(indent, params)
    event_restore_bgm
  end

  # BGS の演奏
  def command_245(indent, params)
    event_play_bgs(params[0])
  end

  # BGS のフェードアウト
  def command_246(indent, params)
    event_stop_bgs(params[0] * 1000)
  end

  # ME の演奏
  def command_249(indent, params)
    event_play_me(params[0])
  end

  # SE の演奏
  def command_250(indent, params)
    event_play_se(params[0])
  end

  # SE の停止
  def command_251(indent, params)
    event_stop_se
  end

  # ムービーの再生
  def command_261(indent, params)
    event_wait until event_message_closed?
    event_wait

    name = params[0]
    Graphics.play_movie(Itefu::Rgss3::Filename::MOVIES_s % name) unless name.empty?
  end

  # マップ名表示の変更
  def command_281(indent, params)
    event_change_if_show_map_name(params[0] == 0)
  end

  # タイルセットの変更
  def command_282(indent, params)
    event_change_tileset(params[0])
  end

  # 戦闘背景の変更
  def command_283(indent, params)
    event_change_battle_background(params[0], params[1])
  end

  # 遠景の変更
  def command_284(indent, params)
    event_change_parallax(params[0], params[1], params[2], params[3], params[4])
  end

  # 指定位置の情報取得
  def command_285(indent, params)
    if params[2] == 0
      x = params[3]
      y = params[4]
    else
      x = variable(params[3])
      y = variable(params[4])
    end

    value = case params[1]
            when 0
              terrain_tag_at_cell(x, y)
            when 1
              event_id_at_cell(x, y)
            when 2..4
              tile_id_at_cell(x, y, params[1] - 2)
            else
              region_id_at_cell(x, y)
            end

    change_variable(params[0], value)
  end

  # バトルの処理
  def command_301(indent, params)
    troop_id = case params[0]
               when 0
                 params[1]
               when 1
                 variable(params[1])
               else  # ランダムエンカウント
                 nil
               end
    event_start_battle(troop_id, params[2], params[3])
    event_wait while event_being_in_battle?
  end
  
  # ショップの処理
  def command_302(indent, params)
    goods = [create_event_shop_item(params)]
    while next_command.code == EventCode::SHOP_SEQUEL
      step_to_next_command
      goods << create_event_shop_item(current_command.parameters)
    end
    
    event_open_shop(goods, params[4])
    event_wait while event_begin_in_shop?
  end
  
  # 名前入力の処理
  def command_303(indent, params)
    event_show_name_input(params[0], params[1])
    event_wait while event_showing_name_input?
  end

  # HP の増減
  def command_311(indent, params)
    value = operated_value(params[2], params[3], params[4])
    iterate_actors(params[0], params[1]) do |actor|
      event_add_actor_hp(actor, value, params[5])
    end
  end

  # MP の増減
  def command_312(indent, params)
    value = operated_value(params[2], params[3], params[4])
    iterate_actors(params[0], params[1]) do |actor|
      event_add_actor_mp(actor, value)
    end
  end

  # ステートの変更
  def command_313(indent, params)
    if params[2] == 0
      iterate_actors(params[0], params[1]) do |actor|
        event_append_actor_state(actor, params[3])
      end
    else
      iterate_actors(params[0], params[1]) do |actor|
        event_remove_actor_state(actor, params[3])
      end
    end
  end

  # 全回復
  def command_314(indent, params)
    iterate_actors(params[0], params[1]) do |actor|
      event_recover_actor(actor)
    end
  end

  # 経験値の増減
  def command_315(indent, params)
    value = operated_value(params[2], params[3], params[4])
    iterate_actors(params[0], params[1]) do |actor|
      event_add_actor_exp(actor, value, params[5])
    end
  end

  # レベルの増減
  def command_316(indent, params)
    value = operated_value(params[2], params[3], params[4])
    iterate_actors(params[0], params[1]) do |actor|
      event_add_actor_level(actor, value, params[5])
    end
  end

  # 能力値の増減
  def command_317(indent, params)
    value = operated_value(params[3], params[4], params[5])
    iterate_actors(params[0], params[1]) do |actor|
      event_add_actor_param(actor, params[2], value)
    end
  end

  # スキルの増減
  def command_318(indent, params)
    if params[2] == 0
      iterate_actors(params[0], params[1]) do |actor|
        event_learn_actor_skill(actor, params[3])
      end
    else
      iterate_actors(params[0], params[1]) do |actor|
        event_forget_actor_skill(actor, params[3])
      end
    end
  end

  # 装備の変更
  def command_319(indent, params)
    event_change_actor_equipment(actor_instance(params[0]), params[1], params[2])
  end

  # 名前の変更
  def command_320(indent, params)
    event_change_actor_name(actor_instance(params[0]), params[1])
  end

  # 職業の変更
  def command_321(indent, params)
    event_change_actor_job(actor_instance(params[0]), params[1])
  end

  # アクターのグラフィック変更
  def command_322(indent, params)
    event_change_actor_graphic(actor_instance(params[0]), params[1], params[2], params[3], params[4])
  end

  # 乗り物のグラフィック変更
  def command_323(indent, params)
    change_vehicle_graphic(params[0], params[1], params[2])
  end

  # 二つ名の変更
  def command_324(indent, params)
    event_change_actor_nickname(actor_instance(params[0]), params[1])
  end

  # 敵キャラの HP 増減
  def command_331(indent, params)
    value = operated_value(params[1], params[2], params[3])
    iterate_enemies(params[0]) do |enemy|
      event_add_enemy_hp(enemy, value, params[4])
    end
  end

  # 敵キャラの MP 増減
  def command_332(indent, params)
    value = operated_value(params[1], params[2], params[3])
    iterate_enemies(params[0]) do |enemy|
      event_add_enemy_mp(enemy, value)
    end
  end

  # 敵キャラのステート変更
  def command_333(indent, params)
    if params[1] == 0
      iterate_enemies(params[0]) do |enemy|
        event_append_enemy_state(enemy, params[2])
      end
    else
      iterate_enemies(params[0]) do |enemy|
        event_remove_enemy_state(enemy, params[2])
      end
    end
  end

  # 敵キャラの全回復
  def command_334(indent, params)
    iterate_enemies(params[0]) do |enemy|
      event_recover_enemy(enemy)
    end
  end

  # 敵キャラの出現
  def command_335(indent, params)
    iterate_enemies(params[0]) do |enemy|
      event_make_enemy_appear(enemy)
    end
  end

  # 敵キャラの変身
  def command_336(indent, params)
    iterate_enemies(params[0]) do |enemy|
      event_make_enemy_transform(enemy, params[1])
    end
  end

  # 戦闘アニメーションの表示
  def command_337(indent, params)
    iterate_enemies(params[0]) do |enemy|
      event_play_effect_animation(enemy, params[1])
      event_wait while event_effect_animation_playing?(enemy)
    end
  end

  # 戦闘行動の強制
  def command_339(indent, params)
    if params[0] == 0
      iterate_enemies(params[1]) do |enemy|
        event_force_enemy_take_action(enemy, params[2], params[3])
        event_wait while event_enemy_being_in_action?(enemy)
      end
    else
      iterate_actors(0, params[1]) do |actor|
        event_force_actor_take_action(actor, params[2], params[3])
        event_wait while event_actor_being_in_action?(actor)
      end
    end
  end

  # バトルの中断
  def command_340(indent, params)
    event_abort_battle
    event_wait while event_aborting_battle?
  end

  # メニュー画面を開く
  def command_351(indent, params)
    event_open_field_menu
    event_wait while event_being_in_field_menu?
  end

  # セーブ画面を開く
  def command_352(indent, params)
    event_open_save_menu
    event_wait while event_being_in_save_menu?
  end

  # ゲームオーバー
  def command_353(indent, params)
    event_game_over
  end

  # タイトル画面に戻す
  def command_354(indent, params)
    event_go_to_title
  end

  # スクリプトの実行
  def command_355(indent, params)
    script = "#{params[0]}"
    while next_command.code == EventCode::SCRIPT_SEQUEL
      step_to_next_command
      script << NEW_LINE
      script << current_command.parameters[0]
    end
    begin
      self.instance_eval(script)
    rescue Exception => e
      ITEFU_DEBUG_OUTPUT_ERROR "Invalid Event Script: #{e.inspect}"
      ITEFU_DEBUG_DUMP_EVENT_INFO
    end
  end
   
  # 条件分岐 [**](選択肢) の場合
  def command_402(indent, params)
    skip_command(indent) if branch_result(indent) != params[0]
  end
  def event_wait_402; end   # メッセージ表示中でも無視して進める

  # 条件分岐 [キャンセル] の場合  
  def command_403(indent, params)
    skip_command(indent) if branch_result(indent) != 4
  end
  def event_wait_403; end   # メッセージ表示中でも無視して進める

  # 条件分岐 [それ以外] の場合
  def command_411(indent, params)
    skip_command(indent) if branch_result(indent)
  end
  def event_wait_411; end   # メッセージ表示中でも無視して進める
    
  # 以上繰り返し
  def command_413(indent, params)
    rewind_command(indent)
  end
  def event_wait_413; end   # メッセージ表示中でも無視して進める

  #　戦闘分岐 [勝った]場合
  def command_601(indent, params)
    skip_command(indent) if branch_result(indent) != Itefu::Rgss3::Definition::Event::Battle::Result::WIN
  end
  def event_wait_601; end   # メッセージ表示中でも無視して進める

  # 戦闘分岐 [逃げた]場合
  def command_602(indent, params)
    skip_command(indent) if branch_result(indent) != Itefu::Rgss3::Definition::Event::Battle::Result::ESCAPE
  end
  def event_wait_602; end   # メッセージ表示中でも無視して進める

  #　戦闘分岐 [負けた]場合
  def command_603(indent, params)
    skip_command(indent) if branch_result(indent) != Itefu::Rgss3::Definition::Event::Battle::Result::LOSE
  end
  def event_wait_603; end   # メッセージ表示中でも無視して進める


  # --------------------------------------------------
  # コマンドの補助機能

  # 「変数」に計算の必要な値を設定する
  def operate_variable(id, operator, operand)
    change_variable(id, operated_variable_value(operator, variable(id), operand))
  rescue TypeError, ZeroDivisionError => e
    ITEFU_DEBUG_OUTPUT_ERROR "#{e.inspect} (id.#{id}, operator.#{operator}, value.#{operand})"
    ITEFU_DEBUG_DUMP_EVENT_INFO
    change_variable(id, 0)
  end

  # @return [Fixnum] 計算した値
  def operated_variable_value(operator, lhs, rhs)
    case operator
    when 0  # 代入
      rhs
    when 1  # 加算
      lhs + rhs
    when 2  # 減算
      lhs - rhs
    when 3  # 乗算
      lhs * rhs
    when 4  # 除算
      lhs / rhs
    when 5  # 剰余
      lhs % rhs
    else
      raise Itefu::Exception::Unreachable
    end
  end

  # @return [Fixnum] 計算をしてその結果を返す
  def operated_value(operator, operand_type, operand)
    case operand_type
    when Itefu::Rgss3::Definition::Event::OperandType::CONSTANT
      # operand = operand
    when Itefu::Rgss3::Definition::Event::OperandType::VARIABLE
      operand = variable(operand)
    else
      raise Itefu::Exception::Unreachable
    end
    
    case operator
    when Itefu::Rgss3::Definition::Event::Operation::ADDITION
      0 + operand
    when Itefu::Rgss3::Definition::Event::Operation::SUBTRACTION
      0 - operand
    else
      raise Itefu::Exception::Unreachable
    end
  end
  
  # マップ中のオブジェクト（プレイヤー、イベント）を取得する
  def mapobject(id)
    case 
    when Itefu::Rgss3::Definition::Event::Id.player?(id)
      player_object
    when Itefu::Rgss3::Definition::Event::Id.event_itself?(id)
      event_object(@event_status.event_id)
    else
      event_object(id)
    end
  end
  
  # アクターへの処理
  def iterate_actors(type, id, &block)
    id = variable(id) if type != 0
    if id && id > 0
      block.call(actor_instance(id))
    else
      party_members.each(&block)
    end
  end
  
  # 敵への処理
  def iterate_enemies(index, &block)
    if index && index >= 0
      block.call(enemy_instance(index))
    else
      troop_members.each(&block)
    end
  end
  
  # ゲームデータから値を取る
  def game_data_operand(type, param1, param2)
    case type
    when 0  # アイテム
      return number_of_items(param1)
    when 1  # 武器
      return number_of_weapons(param1)
    when 2  # 防具
      return number_of_armors(param1)
    when 3  # アクター
      actor = actor_instance(param1)
      case param2
      when 0      # レベル
        return actor_level(actor)
      when 1      # 経験値
        return actor_total_exp(actor)
      when 2      # HP
        return actor_hp(actor)
      when 3      # MP
        return actor_mp(actor)
      when 4..11  # 通常能力値
        return actor_param(actor, param2 - 4)
      end
    when 4  # 敵
      enemy = enemy_instance(param1)
      case param2
      when 0      # HP
        return enemy_hp(enemy)
      when 1      # MP
        return enemy_mp(enemy)
      when 2..9   # 通常能力値
        return enemy_param(enemy, param2 - 2)
      end
    when 5  # マップキャラ
      chara = mapobject(param1)
      case param2
      when 0  # X 座標
        return mapobject_cell_x(chara)
      when 1  # Y 座標
        return mapobject_cell_y(chara)
      when 2  # 向き
        return mapobject_direction(chara)
      when 3  # 画面 X 座標
        return mapobject_screen_x(chara)
      when 4  # 画面 Y 座標
        return mapobject_screen_y(chara)
      end
    when 6  # パーティメンバーのアクターID
      return party_member_id(param1)
    when 7  # その他
      case param1
      when 0  # マップ ID
        return current_map_id
      when 1  # パーティ人数
        return number_of_party_members
      when 2  # ゴールド
        return amount_of_money
      when 3  # 歩数
        return number_of_steps
      when 4  # プレイ時間
        return amount_of_playing_time
      when 5  # タイマー
        return count_of_timer
      when 6  # セーブ回数
        return count_of_saving
      when 7  # 戦闘回数
        return count_of_battle
      end
    end
    raise Itefu::Exception::Unreachable
  end

  # 条件分岐
  def conditional_branch(indent, params)
    case params[0]
    when 0  # スイッチ
      return switch(params[1]) == (params[2] == 0)
    when 1  # 変数
      lhs = variable(params[1])
      rhs = (params[2] == 0) ? params[3] : variable(params[3])
      case params[4]
      when 0  # と同値
        # 正規表現などを使えるように === にしておく
        return (lhs === rhs)
      when 1  # 以上
        return (lhs >= rhs)
      when 2  # 以下
        return (lhs <= rhs)
      when 3  # 超
        return (lhs > rhs)
      when 4  # 未満
        return (lhs < rhs)
      when 5  # 以外
        return (lhs != rhs)
      end
    when 2  # セルフスイッチ
      if @event_status.map_id && @event_status.event_id
        return self_switch(@event_status.map_id, @event_status.event_id, params[1]) == (params[2] == 0)
      else
        ITEFU_DEBUG_OUTPUT_CAUTION("Failed to fetch a self-switch because map id and/or event id is nil")
        ITEFU_DEBUG_DUMP_EVENT_INFO
        return false
      end
    when 3  # タイマー
      return false unless event_timer_working?
      if params[2] == 0
        return count_of_timer >= params[1]
      else
        return count_of_timer <= params[1]
      end
    when 4  # アクター
      actor = actor_instance(params[1])
      case params[2]
      when 0  # パーティにいる
        return party_member?(params[1])
      when 1  # 名前
        return actor_name(actor) == params[3]
      when 2  # 職業
        return actor_job_id(actor) == params[3]
      when 3  # スキル
        return actor_skill?(actor, params[3])
      when 4  # 武器
        return actor_weapon?(actor, params[3])
      when 5  # 防具
        return actor_armor?(actor, params[3])
      when 6  # ステート
        return actor_state?(actor, params[3])
      end
    when 5  # 敵キャラ
      enemy = enemy_instance(params[1])
      case params[2]
      when 0  # 出現している
        return enemy_appeared?(enemy)
      when 1  # ステート
        return enemy_state?(enemy, params[3])
      end
    when 6  # キャラクター
      return mapobject_direction(mapobject(params[1])) == params[2]
    when 7  # ゴールド
      case params[2]
      when 0  # 以上
        return amount_of_money >= params[1]
      when 1  # 以下
        return amount_of_money <= params[1]
      when 2  # 未満
        return amount_of_money < params[1]
      end
    when 8  # アイテム
      return inventory_item?(params[1])
    when 9  # 武器
      if inventory_weapon?(params[1])
        return true
      elsif params[2]
        party_members.each do |member|
          return true if actor_weapon?(member, params[1])
        end
      end
      return false
    when 10  # 防具
      if inventory_armor?(params[1])
        return true
      elsif params[2]
        party_members.each do |member|
          return true if actor_armor?(member, params[1])
        end
      end
      return false
    when 11  # ボタン
      return button_on_pressing?(params[1])
    when 12  # スクリプト
      begin
        return self.instance_eval(params[1])
      rescue => e
        ITEFU_DEBUG_OUTPUT_ERROR "Invalid Event Script: #{e.inspect}"
        ITEFU_DEBUG_DUMP_EVENT_INFO
        return false
      end
    when 13  # 乗り物
      return vehicle_on_rode?(params[1])
    end
  end
  
  def create_event_shop_item(params)
    EventShopItem.new(params[0], params[1], (params[2] != 0) && params[3])
  end


  # --------------------------------------------------
  # アプリケーションで実装する必要のある補助機能
  
  # @return [RPG::CommonEvent] 指定されたidのコモンイベント
  # @param [Fixnum] id コモンイベントの識別子
  def common_event(id)
    raise Itefu::Exception::NotImplemented
  end

  # @param [Interpreter] child 終了したイベントのインスタンス
  # @param [EventStatus] child_status 終了したイベントの実行状態
  def common_event_finished(child, child_status)
  end
  
  # @return [Boolean] スイッチのオンオフ
  # @param [Fixnum] id スイッチの識別子
  def switch(id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @param [Fixnum] id スイッチの識別子
  # @param [Boolean] value スイッチのオンオフ
  def change_switch(id, value)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] スイッチのオンオフ
  # @param [Fixnum] map_id マップの識別子
  # @param [Fixnum] event_id イベントの識別子
  # @param [Fixnum] id スイッチの識別子
  def self_switch(map_id, event_id, id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @param [Fixnum] map_id マップの識別子
  # @param [Fixnum] event_id イベントの識別子
  # @param [Fixnum] id スイッチの識別子
  # @param [Boolean] value スイッチのオンオフ
  def change_self_switch(map_id, event_id, id, value)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] RGSS3の「変数」の値
  # @param [Fixnum] id 変数の識別子
  def variable(id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @param [Fixnum] id RGSS3の「変数」の識別子
  # @param [Fixnum] value 「変数」の値
  def change_variable(id, value)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Object] マップ中のプレイヤーを表すインスタンス
  def player_object
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Object] マップ中のイベントを表すインスタンス
  # @param [Fixnum] id イベントの識別子
  def event_object(id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] マップ座標で横の位置を返す
  # @param [Object] subject 対象のプレイヤーまたはイベント
  def mapobject_cell_x(subject)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] マップ座標で縦の位置を返す
  # @param [Object] subject 対象のプレイヤーまたはイベント
  def mapobject_cell_y(subject)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Itefu::Rgss3::Definition::Direction] 向きを返す
  # @param [Object] subject 対象のプレイヤーまたはイベント
  def mapobject_direction(subject)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] スクリーン座標で横の位置を返す
  # @param [Object] subject 対象のプレイヤーまたはイベント
  def mapobject_screen_x(subject)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] スクリーン座標で縦の位置を返す
  # @param [Object] subject 対象のプレイヤーまたはイベント
  def mapobject_screen_y(subject)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 地形タグを取得する
  # @param [Fixnum] cell_x 対象のマップ横座標
  # @param [Fixnum] cell_y 対象のマップ縦座標
  def terrain_tag_at_cell(cell_x, cell_y)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] イベントがあればそのIDを取得する
  # @param [Fixnum] cell_x 対象のマップ横座標
  # @param [Fixnum] cell_y 対象のマップ縦座標
  def event_id_at_cell(cell_x, cell_y)
    raise Itefu::Exception::NotImplemented
  end

  # @return [Fixnum] タイルIDを取得する
  # @param [Fixnum] cell_x 対象のマップ横座標
  # @param [Fixnum] cell_y 対象のマップ縦座標
  # @param [Fixnum] layer_index 何番目のタイルIDを取得するか [0-2]
  def tile_id_at_cell(cell_x, cell_y, layer_index)
    raise Itefu::Exception::NotImplemented
  end

  # @return [Fixnum] リージョンIDを取得する
  # @param [Fixnum] cell_x 対象のマップ横座標
  # @param [Fixnum] cell_y 対象のマップ縦座標
  def region_id_at_cell(cell_x, cell_y)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Enumrator] パーティメンバーをイテレーションするEnumratorを返す
  # @note 返すインスタンスはeachを実装していれば何でもよい
  def party_members
    raise Itefu::Exception::NotImplemented
  end

  # @return [Fixnum] パーティメンバーの識別子を返す
  # @param [Fixnum] index 何番目のメンバーのを得るか
  def party_member_id(index)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] 指定したアクターがパーティにいるか
  # @param [Fixnum] id 確認するアクターの識別子
  def party_member?(id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Object] アクターのインスタンスを取得する
  # @param [Fixnum] id 取得するアクターの識別子
  def actor_instance(id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アクターのレベルを返す
  # @param [Object] actor 対象のアクター
  def actor_level(actor)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アクターの総経験値を返す
  # @param [Object] actor 対象のアクター
  def actor_total_exp(actor)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アクターのHPを返す
  # @param [Object] actor 対象のアクター
  def actor_hp(actor)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アクターのMPを返す
  # @param [Object] actor 対象のアクター
  def actor_mp(actor)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アクターの能力値を返す
  # @param [Object] actor 対象のアクター
  # @param [Itefu::Rgss3::Definition::Status::Param] param_id 能力値の識別子
  def actor_param(actor, param_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [String] アクターの名前を返す
  # @param [Object] actor 対象のアクター
  def actor_name(actor)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アクターの職業の識別子を返す
  # @param [Object] actor 対象のアクター
  def actor_job_id(actor)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] アクターがスキルを習得しているか
  # @param [Object] actor 対象のアクター
  # @oarams [Fixnum] skill_id スキルの識別子
  def actor_skill?(actor, skill_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] アクターが武器を装備しているか
  # @param [Object] actor 対象のアクター
  # @oarams [Fixnum] weapon_id 武器の識別子
  def actor_weapon?(actor, weapon_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] アクターが防具を装備しているか
  # @param [Object] actor 対象のアクター
  # @oarams [Fixnum] armor_id 防具の識別子
  def actor_armor?(actor, armor_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] アクターが指定したステートになっているか
  # @param [Object] actor 対象のアクター
  # @oarams [Fixnum] state_id ステートの識別子
  def actor_state?(actor, state_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Enumrator] 敵グループをイテレーションするEnumratorを返す
  # @note 返すインスタンスはeachを実装していれば何でもよい
  def troop_members
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Object] 敵のインスタンスを取得する
  # @param [Fixnum] index 敵グループ内の番号
  def enemy_instance(index)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 敵のHPを返す
  # @param [Object] enemy 対象の敵
  def enemy_hp(enemy)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 敵のMPを返す
  # @param [Object] enemy 対象の敵
  def enemy_mp(enemy)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 敵の能力値を返す
  # @param [Object] enemy 対象の敵
  # @param [Itefu::Rgss3::Definition::Status::Param] param_id 能力値の識別子
  def enemy_param(enemy, padam_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] 敵が出現済みか
  # @param [Object] enemy 対象の敵
  def enemy_appeared?(enemy)
    raise Itefu::Exception::NotImplemented
  end

  # @return [Boolean] 敵が指定したステートになっているか
  # @param [Object] enemy 対象の敵
  # @oarams [Fixnum] state_id ステートの識別子
  def enemy_state?(enemy, state_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] アイテムを所持しているか
  def inventory_item?(item_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] 武器を所持しているか
  def inventory_weapon?(weapon_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] 防具を所持しているか
  def inventory_armor?(armor_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] ボタンを押しているか
  # @params [Itefu::Rgss3::Input::Code] button_id ボタンの識別子
  def button_on_pressing?(d)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Boolean] 乗り物に乗っているか
  # @param [Itefu::Rgss3::Definition::Event::VehicleType] vehicle_type 乗り物の種類
  def vehicle_on_rode?(vehicle_type)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] アイテムの数を返す
  # @param [Fixnum] item_id アイテムの識別子
  def number_of_items(item_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 武器の数を返す
  # @param [Fixnum] weapon_id 数を得たい武器の識別子
  def number_of_weapons(weapon_id)
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 防具の数を返す
  # @param [Fixnum] armor_id 数を得たい防具の識別子
  def number_of_armors(armor_id)
    raise Itefu::Exception::NotImplemented
  end

  # @return [Fixnum] パーティの人数を返す
  def number_of_party_members
    raise Itefu::Exception::NotImplemented
  end

  # @return [Fixnum] 現在のマップID
  def current_map_id
    @event_status.current_map_id
  end
  
  # @return [Fixnum] 所持している金額を返す
  def amount_of_money
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] いままでの歩行数を返す
  def number_of_steps
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] いままでのプレイ時間を返す
  def amount_of_playing_time
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 「タイマー」のカウント数を返す
  def count_of_timer
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] セーブした回数を返す
  def count_of_saving
    raise Itefu::Exception::NotImplemented
  end
  
  # @return [Fixnum] 戦闘を行った回数を返す
  def count_of_battle
    raise Itefu::Exception::NotImplemented
  end
  

  # --------------------------------------------------
  # アプリケーションで実装する必要のあるイベントの処理
  
  # メッセージを表示する
  # @param [String] message 表示する文章
  # @param [String] face_name 顔グラフィック名
  # @param [Fixnum] face_index 顔グラフィックのアトラス上の番号
  # @param [Itefu::Rgss3::Definition::Event::Message::Background] background 背景
  # @param [Itefu::Rgss3::Definition::Event::Message::Position] position 表示位置
  def event_show_message(message, face_name, face_index, background, position)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] メッセージを表示中か
  def event_message_showing?; false; end
  
  # @return [Boolean] メッセージを表示するUIが閉じているか
  # @note 開閉中に showing?.! && closed?.! というケースがあり得る
  def event_message_closed?; true; end

  # 選択肢を表示する
  # @param [Array<String>] choices 選択肢
  # @param [Fixnum] cancel_value キャンセル時の値(-1の場合はキャンセル無効)
  def event_show_choices(choices, cancel_value)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 選択肢を表示中か
  def event_choices_showing?; false; end
  
  # 数値入力を表示する
  # @param [Fixnum] variable_id 入力された値を受け取る「変数」のID
  # @param [Fixnum] digit 入力欄の桁数
  def event_show_numeric_input(variable_id, digit)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 数値入力を表示中か
  def event_numeric_input_showing?; false; end

  # アイテム選択を表示する
  # @param [Fixnum] variable_id 選択されたアイテムのIDを受け取る「変数」のID
  def event_show_item_select(variable_id)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] アイテム選択を表示中か
  def event_item_select_showing?; false; end

  # スクロール文章を表示する
  # @param [String] text 表示する文章
  # @param [Fixnum] speed スクロールする速さ [0-8]
  # @param [Boolean] not_to_fast_feed 早送り無効
  def event_show_scrolling_text(text, speed, not_to_fast_feed)
    raise Itefu::Exception::NotSupported
  end
  
  # @return [Boolean] スクロール文章を表示中か
  def event_scrolling_text_showing?; false; end

  # タイマーのカウントダウンを開始する
  # @param [Fixnum] frame_to_count_down タイマーの初期値
  # @note frame_to_count_down は時間で入力した値が60fpsでのフレーム数に換算されて与えられる
  def event_start_timer(frame_to_count_down)
    raise Itefu::Exception::NotSupported
  end

  # タイマーを停止する
  def event_stop_timer
    raise Itefu::Exception::NotSupported
  end
  
  # @return [Boolean] タイマーが動作しているか
  def event_timer_working?
    raise Itefu::Exception::NotSupported
  end
  
  # 所持金を増減させる
  # @param [Fixnum] diff 増減させる量
  def event_add_money(diff)
    raise Itefu::Exception::NotSupported
  end
  
  # アイテムを増減させる
  # @param [Fixnum] item_id アイテムの識別子
  # @param [Fixnum] diff 増減させる量
  def event_add_item(item_id, diff)
    raise Itefu::Exception::NotSupported
  end
  
  # 武器を増減させる
  # @param [Fixnum] weapon_id 武器の識別子
  # @param [Fixnum] diff 増減させる量
  # @param [Boolean] strip 装備中の武器を含めるか
  def event_add_weapon(weapon_id, diff, strip)
    raise Itefu::Exception::NotSupported
  end

  # 防具を増減させる
  # @param [Fixnum] armor_id 防具の識別子
  # @param [Fixnum] diff 増減させる量
  # @param [Boolean] strip 装備中の防具を含めるか
  def event_add_armor(armor_id, diff, strip)
    raise Itefu::Exception::NotSupported
  end

  # パーティに参加させる
  # @param [Fixnum] actor_id アクターの識別子
  # @param [Boolean] init ステータスを初期化するか
  def event_join_party(actor_id, init)
    raise Itefu::Exception::NotSupported
  end

  # パーティを離脱させる
  # @param [Fixnum] actor_id アクターの識別子
  def event_leave_party(actor_id)
    raise Itefu::Exception::NotSupported
  end
  
  # 戦闘BGMを変更する
  def event_change_battle_bgm(bgm)
    raise Itefu::Exception::NotSupported
  end
  
  # 戦闘MEを変更する
  def event_change_battle_me(me)
    raise Itefu::Exception::NotSupported
  end
  
  # セーブ禁止かどうかを切り替える
  # @param [Boolean] prohibited セーブ禁止か
  def event_change_save_prohibition(prohibited)
    raise Itefu::Exception::NotSupported
  end

  # メニュー禁止かどうかを切り替える
  # @param [Boolean] prohibited メニュー禁止か
  def event_change_menu_prohibition(prohibited)
    raise Itefu::Exception::NotSupported
  end

  # エンカウント禁止かどうかを切り替える
  # @param [Boolean] prohibited エンカウント 禁止か
  def event_change_encounter_prohibition(prohibited)
    raise Itefu::Exception::NotSupported
  end

  # 並び替え禁止かどうかを切り替える
  # @param [Boolean] prohibited 並び替えを禁止するか
  def event_change_formation_prohibition(prohibited)
    raise Itefu::Exception::NotSupported
  end

  # 場所移動
  # @param [Fixnum] map_id 移動先のマップ識別子
  # @param [Fixnum] cell_x 移動先のマップ横座標
  # @param [Fixnum] cell_x 移動先のマップ縦座標
  # @param [Itefu::Rgss3::Definition::Direction::Orthogonal|NOP] direction 移動後の向き
  # @param [Itefu::Rgss3::Definition::Event::FadeType] fade_type フェードの種類
  def event_move_player(map_id, cell_x, cell_y, direction, fade_type)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 場所移動の処理中か
  def event_player_moving?; false; end

  # 乗り物の位置を移動
  # @param [Itefu::Rgss3::Definition::Event::VehicleType] vehicle_type 乗り物の種類
  # @param [Fixnum] map_id 移動先のマップ識別子
  # @param [Fixnum] cell_x 移動先のマップ横座標
  # @param [Fixnum] cell_x 移動先のマップ縦座標
  def event_move_vehicle(vehicle_type, map_id, cell_x, cell_y)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 乗り物移動の処理中か
  # @param [Itefu::Rgss3::Definition::Event::VehicleType] vehicle_type 乗り物の種類
  def event_vehicle_moving?(vehicle_type); false; end

  # イベントの移動
  # @param [Object] subject 移動させるイベント
  # @param [Fixnum] cell_x 移動先のマップ横座標
  # @param [Fixnum] cell_x 移動先のマップ縦座標
  # @param [Itefu::Rgss3::Definition::Direction::Orthogonal|NOP] direction 移動後の向き
  def event_move_event(subject, cell_x, cell_y, direction)
    raise Itefu::Exception::NotSupported
  end

  # イベントの位置の交換
  # @param [Object] subject 移動させるイベント
  # @param [Object] object 交換相手のイベント
  # @param [Itefu::Rgss3::Definition::Direction::Orthogonal|NOP] direction 移動後の向き
  def event_swap_event(subject, object, direction)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] イベントの移動を処理中か
  # @param [Object] subject 移動しているイベント
  def event_event_moving?(subject); false; end

  # 画面をスクロールする
  # @param [Itefu::Rgss3::Definition::Direction::Orthogonal|NOP] direction 移動する方向
  # @param [Fixnum] distance 何セル分スクロールするか
  # @param [Itefu::Rgss3::Definition::Event::Speed] speed 移動速度
  def event_scroll(direction, distance, speed)
    raise Itefu::Exception::NotSupported
  end

  #@param [Boolean] 画面のスクロール処理中か
  def event_scrolling?; false; end

  # ルートを設定する
  # @param [Object] subject ルートを設定する対象
  # @param [RPG::MoveRoute] route ルート情報
  # @param [Object] object 「プレイヤーの方を向く」対象
  # @note objectは、subjectがイベントの場合はプレイヤーを、プレイヤーの場合は「このイベント」を指す
  def event_assign_route(subject, route, object)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] ルート移動の処理中か
  # @param [Object] subject ルート移動しているプレイヤーかイベント
  # @note 「移動が終わるまでウェイト」するときだけ呼ばれる
  def event_routing?(subject); false; end
  
  # 乗り物の乗り降り
  # @note 乗り物に乗っていないときは、目の前に乗り物があれば乗る、という挙動をする
  def event_get_vehicle_on_off
    raise Itefu::Exception::NotSupported
  end

  # 透明状態の変更
  # @param [Boolean] transparent 透明か
  # @note プレイヤーの透明状態を変更する
  def event_change_transparency(transparent)
    raise Itefu::Exception::NotSupported
  end

  # エフェクトアニメーションを再生する
  # @param [Object] subject 再生位置の基準になるプレイヤーまたはイベントまたは敵
  # @param [Fixnum] anime_id アニメーションの識別子
  # @note マップであればプレイヤーかイベント、戦闘中であれば敵がsubjectに設定されて呼ばれる
  def event_play_effect_animation(subject, anime_id)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] エフェクトアニメーションを再生中か
  # @param [Object] subject 再生位置の基準になるプレイヤーまたはイベント
  # @note 「表示終了までウェイト」するときだけ呼ばれる
  def event_effect_animation_playing?(subject); false; end

  # フキダシアイコンを表示する
  # @param [Object] subject 表示するプレイヤーまたはイベント
  # @param [Fixnum] baloon_id フキダシアイコンの識別子
  def event_show_balloon(subject, balloon_id)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] フキダシアイコンを表示中か
  # @param [Object] subject 表示しているプレイヤーまたはイベント
  # @note 「表示終了までウェイト」するときだけ呼ばれる
  def event_balloon_showing?(subject); false; end

  # このイベントを一時的に消去する
  # @note マップを出入りしなおすまではイベントが存在しないことになる
  def event_disable_this_event
    raise Itefu::Exception::NotSupported
  end

  # 隊列を表示するか切り替える
  # @param [Boolean] to_show 隊列を表示するか
  def event_change_if_show_followers(to_show)
    raise Itefu::Exception::NotSupported
  end

  # 隊列を集合する
  def event_gather_followers
    raise Itefu::Exception::NotSupported
  end

  # @param [Boolean] 隊列を集合中か
  def event_gathering_followers?; false; end

  # 画面をフェードアウトする
  def event_fade_out
    raise Itefu::Exception::NotSupported
  end

  # 画面をフェードインする
  def event_fade_in
    raise Itefu::Exception::NotSupported
  end
  
  # 画面をフェードアウトしている最中か
  def event_fading_out?; false; end

  # 画面をフェードインしている最中か
  def event_fading_in?; false; end

  # 画面の色調の変更
  # @param [Tone] tone この色調にする
  # @param [Fixnum] duration 何フレームかけて色調を変更するか
  def event_change_tone(tone, duration)
    raise Itefu::Exception::NotSupported
  end

  # 画面のフラッシュ
  # @param [Color] color フラッシュする色
  # @param [Fixnum] duration 何フレームだけフラッシュするか
  def event_flash(color, duration)
    raise Itefu::Exception::NotSupported
  end

  # 画面のシェイク
  # @param [Fixnum] power 強さ
  # @param [Fixnum] speed 速さ
  # @param [Fixnum] duration 何フレームだけシェイクするか
  def event_shake(power, speed, duration)
    raise Itefu::Exception::NotSupported
  end

  # ピクチャを表示する
  # @param [Fixnum] index 番号
  # @param [String] name ピクチャグラフィック
  # @param [Itefu::Rgss3::Definition::Event::Picture::Origin] origin 表示位置原点
  # @param [Fixnum] x 表示するスクリーン座標横位置
  # @param [Fixnum] y 表示するスクリーン座標縦位置
  # @param [Float] zoom_x 横拡大率 (1.0で等倍)
  # @param [Float] zoom_y 縦拡大率 (1.0で等倍)
  # @param [Fixnum] opacity 不透明度 [0-255]
  # @param [Itefu::Rgss3::Sprite::BlendingType] blend_type 合成方法
  def event_show_picture(index, name, origin, x, y, zoom_x, zoom_y, opacity, blend_type)
    raise Itefu::Exception::NotSupported
  end
  
  # ピクチャを移動する
  # @param [Fixnum] index 番号
  # @param [Itefu::Rgss3::Definition::Event::Picture::Origin] origin 表示位置原点
  # @param [Fixnum] x 表示するスクリーン座標横位置
  # @param [Fixnum] y 表示するスクリーン座標縦位置
  # @param [Float] zoom_x 横拡大率 (1.0で等倍)
  # @param [Float] zoom_y 縦拡大率 (1.0で等倍)
  # @param [Fixnum] opacity 不透明度 [0-255]
  # @param [Itefu::Rgss3::Sprite::BlendingType] blend_type 合成方法
  # @param [Fixnum] duration 何フレームかけて移動するか
  def event_move_picture(index, origin, x, y, zoom_x, zoom_y, opacity, blend_type, duration)
    raise Itefu::Exception::NotSupported
  end
  
  # ピクチャを回転する
  # @param [Fixnum] index 番号
  # @param [Fixnum] angle 回転角度 [0-360)
  def event_rotate_picture(index, angle)
    raise Itefu::Exception::NotSupported
  end
  
  # ピクチャの色調を変更する
  # @param [Fixnum] index 番号
  # @param [Tone] tone この色調にする
  # @param [Fixnum] duration 何フレームかけて色調を変更するか
  def event_change_picture_tone(index, tone, duration)
    raise Itefu::Exception::NotSupported
  end
  
  # ピクチャを消去する
  # @param [Fixnum] index 番号
  def event_erase_picture(index)
    raise Itefu::Exception::NotSupported
  end

  # 天候を変更する
  # @param [Itefu::Rgss3::Definition::Event::WeatherType] weather_type 天候の種類
  # @param [Fixnum] power 強さ [0-9]
  # @param [Fixnum] duration 何フレームかけて天候を切り替えるか
  def event_change_weather(weather_type, power, duration)
    raise Itefu::Exception::NotSupported
  end

  # BGMを再生する
  # @param [RPG::BGM] bgm 再生するBGMのインスタンス
  def event_play_bgm(bgm)
    raise Itefu::Exception::NotSupported
  end

  # BGMを停止する
  # @param [Fixnum] rt リリースタイム (ミリ秒)
  def event_stop_bgm(rt)
    raise Itefu::Exception::NotSupported
  end

  # BGMを記録する
  def event_cache_bgm
    raise Itefu::Exception::NotSupported
  end

  # 記録したBGMを再生する
  def event_restore_bgm
    raise Itefu::Exception::NotSupported
  end

  # BGSを再生する
  # @param [RPG::BGS] bgs 再生するBGSのインスタンス
  def event_play_bgs(bgs)
    raise Itefu::Exception::NotSupported
  end

  # BGSを停止する
  # @param [Fixnum] rt リリースタイム (ミリ秒)
  def event_stop_bgs(rt)
    raise Itefu::Exception::NotSupported
  end

  # MEを再生する
  # @param [RPG::ME] me 再生するMEのインスタンス
  def event_play_me(me)
    raise Itefu::Exception::NotSupported
  end
  
  # SEを再生する
  # @param [RPG::SE] se 再生するSEのインスタンス
  def event_play_se(se)
    raise Itefu::Exception::NotSupported
  end
  
  # SEを停止する
  def event_stop_se
    raise Itefu::Exception::NotSupported
  end

  # マップ名を表示するかどうかを切り替える
  # @param [Boolean] to_show マップ名を表示するか
  def event_change_if_show_map_name(to_show)
    raise Itefu::Exception::NotSupported
  end

  # タイルセットを変更する
  # @param [Fixnum] tileset_id タイルセットの識別子
  def event_change_tileset(tileset_id)
    raise Itefu::Exception::NotSupported
  end

  # 戦闘画面の背景を変更する
  # @param [String] back1 Battlebacks1のグラフィック名
  # @param [String] back1 Battlebacks2のグラフィック名
  def event_change_battle_background(back1, back2)
    raise Itefu::Exception::NotSupported
  end

  # 遠景を変更する
  # @param [String] name 遠景のグラフィック名
  # @param [Boolean] loop_x 横方向にループするか
  # @param [Boolean] loop_y 縦方向にループするか
  # @param [Fixnum] sx 遠景を横方向に自動スクロールするフレームごとの量
  # @param [Fixnum] sy 遠景を縦方向に自動スクロールするフレームごとの量
  def event_change_parallax(name, loop_x, loop_y, sx, sy)
    raise Itefu::Exception::NotSupported
  end
  
  # 戦闘を開始する
  # @param [Fixnum|NilClass] troop_id 戦う敵グループの識別子
  # @note ランダムエンカウントの場合はtroop_idにnilが指定される
  def event_start_battle(troop_id, escape, lose)
    raise Itefu::Exception::NotSupported
  end
  
  # 戦闘中か
  # @note 戦闘をマップと同じシーンで処理する場合にはここで待つようにする
  def event_being_in_battle?; false; end
  
  # ショップを開く
  # @param [Array<EventShopItem>] goods 販売物
  # @param [Boolean] only_to_buy 購入のみできる（売却不可能な）ショップか
  def event_open_shop(goods, only_to_buy)
    raise Itefu::Exception::NotSupported
  end
  
  # @return [Boolean] ショップを開いているか
  # @note ショップをマップと同じシーンで処理する場合にはここで待つようにする
  def event_begin_in_shop?; false; end

  # 名前入力欄を開く  
  # @param [Fixnum] actor_id アクターの識別子
  # @oaram [Fixnum] limit 制限文字数
  def event_show_name_input(actor_id, limit)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 名前入力欄を開いているか
  def event_showing_name_input?; false; end

  # アクターのHPを増減させる
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] diff 増減値
  # @param [Boolean] to_die 必要であれば戦闘不能にするか
  def event_add_actor_hp(actor, diff, to_die)
    raise Itefu::Exception::NotSupported
  end

  # アクターのMPを増減させる
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] diff 増減値
  def event_add_actor_mp(actor, value)
    raise Itefu::Exception::NotSupported
  end

  # ステートを付与する
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] status_id ステートの識別子
  def event_append_actor_state(actor, state_id)
    raise Itefu::Exception::NotSupported
  end

  # ステートを除去する
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] status_id ステートの識別子
  def event_remove_actor_state(actor, state_id)
    raise Itefu::Exception::NotSupported
  end
  
  # 全回復させる
  # @param [Object] actor 対象のアクター
  def event_recover_actor(actor)
    raise Itefu::Exception::NotSupported
  end
  
  # 経験値の増減
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] diff 増減値
  # @param [Boolean] to_notify レベルアップした際にメッセージを表示するか
  def event_add_actor_exp(actor, diff, to_notify)
    raise Itefu::Exception::NotSupported
  end

  # レベルの増減
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] diff 増減値
  # @param [Boolean] to_notify レベルアップのメッセージを表示するか
  def event_add_actor_level(actor, diff, to_notify)
    raise Itefu::Exception::NotSupported
  end

  # 能力値を増減させる
  # @param [Object] actor 対象のアクター
  # @param [Itefu::Rgss3::Definition::Status::Param] param_id 能力値の識別子
  # @param [Fixnum] diff 増減値
  def event_add_actor_param(actor, param_id, diff)
    raise Itefu::Exception::NotSupported
  end

  # スキルを習得する
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] skill_id スキルの識別子
  def event_learn_actor_skill(actor, skill_id)
    raise Itefu::Exception::NotSupported
  end

  # スキルを忘れる
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] skill_id スキルの識別子
  def event_forget_actor_skill(actor, skill_id)
    raise Itefu::Exception::NotSupported
  end

  # 装備を変更する
  # @param [Object] actor 対象のアクター
  # @param [Itefu::Rgss3::Definition::Equipment::Slot] slot_id スロットの識別子
  # @param [Fixnum] equip_id 武器または防具の識別子
  # @note equip_id が武器か防具かはslot_idで決まる
  # @note 装備をはずす場合は equip_id に 0 が入る
  def event_change_actor_equipment(actor, slot_id, equip_id)
    raise Itefu::Exception::NotSupported
  end

  # アクターの名前を変更する
  # @param [Object] actor 対象のアクター
  # @param [String] name 新しい名前
  def event_change_actor_name(actor, name)
    raise Itefu::Exception::NotSupported
  end

  # アクターの職業を変更する
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] job_id 職業の識別子
  def event_change_actor_job(actor, job_id)
    raise Itefu::Exception::NotSupported
  end

  # アクターのグラフィックを変更する
  # @param [Object] actor 対象のアクター
  # @param [String] chara_name 歩行チップのグラフィック名
  # @param [Fixnum] chara_index 歩行チップの番号
  # @param [String] face_name 顔グラフィック名
  # @param [Fixnum] face_index 顔グラフィックの番号
  def event_change_actor_graphic(actor, chara_name, chara_index, face_name, face_index)
    raise Itefu::Exception::NotSupported
  end

  # 乗り物のグラフィックを変更する
  # @param [Itefu::Rgss3::Definition::Event::VehicleType] vehicle_type 乗り物の種類
  # @param [String] chara_name 歩行チップのグラフィック名
  # @param [Fixnum] chara_index 歩行チップの番号
  def change_vehicle_graphic(vehicle_type, chara_name, chara_index)
    raise Itefu::Exception::NotSupported
  end

  # アクターの二つ名を変更する
  # @param [Object] actor 対象のアクター
  # @param [String] nickname 新しい二つ名
  def event_change_actor_nickname(actor, nickname)
    raise Itefu::Exception::NotSupported
  end

  # 敵のHPを増減させる
  # @param [Object] enemy 対象の敵
  # @param [Fixnum] diff 増減値
  # @param [Boolean] to_die 必要であれば戦闘不能にするか
  def event_add_enemy_hp(enemy, diff, to_die)
    raise Itefu::Exception::NotSupported
  end

  # 敵のMPを増減させる
  # @param [Object] enemy 対象の敵
  # @param [Fixnum] diff 増減値
  def event_add_enemy_mp(enemy, value)
    raise Itefu::Exception::NotSupported
  end

  # 敵にステートを付与する
  # @param [Object] enemy 対象の敵
  # @param [Fixnum] status_id ステートの識別子
  def event_append_enemy_state(enemy, state_id)
    raise Itefu::Exception::NotSupported
  end

  # 敵のステートを除去する
  # @param [Object] enemy 対象の敵
  # @param [Fixnum] status_id ステートの識別子
  def event_remove_enemy_state(enemy, state_id)
    raise Itefu::Exception::NotSupported
  end
  
  # 敵を全回復させる
  # @param [Object] enemy 対象の敵
  def event_recover_enemy(enemy)
    raise Itefu::Exception::NotSupported
  end

  # 敵を出現させる
  # @param [Object] enemy 対象の敵
  def event_make_enemy_appear(enemy)
    raise Itefu::Exception::NotSupported
  end

  # 敵を変身させる
  # @param [Object] enemy 対象の敵
  # @param [Fixnum] enemy_id 変身後の敵の識別子
  def event_make_enemy_transform(enemy, enemy_id)
    raise Itefu::Exception::NotSupported
  end
  
  # 戦闘中の行動を強制する
  # @param [Object] actor 対象のアクター
  # @param [Fixnum] skill_id スキルの識別子
  # @param [Itefu::Rgss3::Definition::Event::Battle::Target] target_index 攻撃の対象
  def event_force_actor_take_action(actor, skill_id, target_index)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 戦闘時、プレイヤーが行動中か
  # @param [Object] actor 対象のアクター
  def event_actor_being_in_action?(actor); false; end

  # 敵の戦闘中の行動を強制する
  # @param [Object] enemy 対象の敵
  # @param [Fixnum] skill_id スキルの識別子
  # @param [Itefu::Rgss3::Definition::Event::Battle::Target] target_index 攻撃の対象
  def event_force_enemy_take_action(enemy, skill_id, target_index)
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] 戦闘時、敵が行動中か
  # @param [Object] enemy 対象の敵
  def event_enemy_being_in_action?(enemy); false; end

  # 戦闘を中断する
  def event_abort_battle
    raise Itefu::Exception::NotSupported
  end

  # 戦闘の中断処理を行っている最中か
  def event_aborting_battle?; false; end

  # メニュー画面を開く
  def event_open_field_menu
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] メニュー画面を開いているか
  # @note メニュー画面をマップと同じシーンで処理する場合にはここで待つようにする
  def event_being_in_field_menu?; false; end

  # セーブ画面を開く
  def event_open_save_menu
    raise Itefu::Exception::NotSupported
  end

  # @return [Boolean] セーブ画面を開いているか
  # @note セーブ画面をマップと同じシーンで処理する場合にはここで待つようにする
  def event_being_in_save_menu?; false; end

  # ゲームオーバー画面に移動する
  def event_game_over
    raise Itefu::Exception::NotSupported
  end

  # タイトル画面に移動する
  def event_go_to_title
    raise Itefu::Exception::NotSupported
  end

end
