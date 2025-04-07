require("src/startup")

print("-----------------------------")
print("  3rd_trials.lua - " .. script_version .. "")
print("  Trials script for " .. game_name .. "")
print("  Last tested Fightcade version: " .. fc_version .. "")
print("  project url: https://github.com/Grouflon/3rd_training_lua")
print("-----------------------------")
print("WIP")
--print("This is a proof of concept which has only a handful of Hugo trials")
--print("Command List:")
print("Command List:")
print("- Enter training menu by pressing \"Start\" while in game")
print("- Reset the current trial by pressing coin")


assert_enabled = true
developer_mode = true

require("src/tools")
require("src/memory_adresses")
require("src/framedata")
require("src/gamestate")
require("src/moves")
require("src/recording")
require("src/draw")
require("src/display")
require("src/menu_widgets")

-- TRIALS
-- Modify the table to read the json file add the metadata to the table
-- trial_details are in the following format:
--- _trial_details = {
---   [1] = {
---     [1] = {
---       trial_name = "Trial 1",
---       trial_description = "Trial 1 description",
---       char = "Ryu",
---       version = 1,
---       p1_sequence = {1, 2, 3},
---       hits = {1, 2, 3},
---     },
---     [2] = {
---       trial_name = "Trial 2",
---       trial_description = "Trial 2 description",
---       char = "Ryu",
---       version = 1,
---       p1_sequence = {1, 2, 3},
---       hits = {1, 2, 3},
---     },
---     [3] = {...}
---   },
---   [2] = {
---     [1] = {
---       trial_name = "Trial 1",
---       trial_description = "Trial 1 description",
---       char = "Ken",
---       version = 1,
---       p1_sequence = {1, 2, 3},
---       hits = {1, 2, 3},
---     },
---     [2] = {...}
---   },
--- }
function load_trials_list(load_trial_details)
  local _load_trial_details = load_trial_details or false
  local _trials = {} -- Old list of trials
  local _trial_details = {}
  local _base_path = "data/sfiii3nr1/trials/base"
  for _i, _char_str in ipairs(characters) do
    local _char_path = string.format("%s/%s", _base_path, _char_str)
    local _all_char_trials = {}

    --print (_char_path)
    local _trials_list = list_directory_content(_char_path)
    for __, _path in ipairs(_trials_list) do
      table.insert(_trials, string.format("%s/%s", _char_path, _path))

      if _load_trial_details then
        -- Check to see if there is a data.json file
        local _char_trial_data_json = {}
        local f=io.open(string.format("%s/%s/%s/data.json", _base_path, _char_str, _path), "r")
        if file_exists(string.format("%s/%s/%s/data.json", _base_path, _char_str, _path)) then
          local _trial_data = read_object_from_json_file(string.format("%s/%s/%s/data.json", _base_path, _char_str, _path))
          
          -- Check that data.json is valid
          if validate_trial_data(_trial_data) then
            -- Since the trial data is valid, we can add it to _trial_details
            table.insert(_all_char_trials, _trial_data)
          else
            print(string.format("Failed to load trial data \"%s/%s/%s\"",_base_path, _char_str, _path))
          end

        else
          print(string.format("Can't open trial: missing data.json: \"%s\"", string.format("%s/%s/%s/data.json", _base_path, _char_str, _path)))
        end
      end
      
      if developer_mode then
        print(_path)
      end
    end
    -- Add all the character trials to _trial_details, unsure if this is working
    if _load_trial_details then
      _trial_details[_i] = _all_char_trials
    end
  end
  if developer_mode and _load_trial_details then
    for char_id, trials in ipairs(_trial_details) do
        print(string.format("Trials for character id:char: "..char_id..":"..characters[char_id]))
        for _i, trial in ipairs(trials) do
          print(string.format("  trial_name: "..trial.trial_name))
          print(string.format("  trial_description: "..trial.trial_description))
          print(string.format("  trial_char: "..trial.char))
          print(string.format("  trial_version: %s", trial.version))
          -- Table print(string.format("  %s", trial.p1_sequence))
          -- Table print(string.format("  %s", trial.hits))
        end
    end
  end
  return _trials, _trial_details
end

-- Make sure the trial data contaiins the following keys:
-- char, version, p1_sequence, hits, trial_name, trial_description
function validate_trial_data(trial_data)
  local _required_keys = {
    "char",
    "version",
    "p1_sequence",
    "hits",
    "trial_name",
    "trial_description"
  }
  for _i, _key in ipairs(_required_keys) do
    if trial_data[_key] == nil then
      print(string.format("Missing key \"%s\" in trial data", _key))
      return false
    end
  end
  return true
end

-- Ensure the file 'file_path' exists
-- Returns true if the file exists, false otherwise
function file_exists(file_path)
  local f=io.open(file_path,"r")
  if f~=nil then io.close(f) return true else return false end
end

function load_trial_definition(_path)
  local _savestate_path = string.format("%s/savestate.fs", _path)
  if not do_file_exists(_savestate_path) then
    print(string.format("Can't open trial: missing savestate \"%s\"", _savestate_path))
  end

  local _data_path = string.format("%s/data.json", _path)
  if not do_file_exists(_data_path) then
    print(string.format("Can't open trial: missing savestate \"%s\"", _data_path))
  end

  local _trial_definition = {}
  _trial_definition.data = read_object_from_json_file(_data_path)
  _trial_definition.savestate = savestate.create(_savestate_path)

  if developer_mode then
    print(string.format("Loaded trial \"%s\"", _path))
  end

  return _trial_definition
end

-- WATCH
function init_trial_watch(_trial_watch)
  local _object = _trial_watch or {}

  _object.is_started = false
  _object.hits = {}

  return _object
end

function update_trial_watch(_trial_watch, _attacker, _defender)
  t_assert(_trial_watch ~= nil)
  t_assert(_attacker ~= nil)
  t_assert(_defender ~= nil)
  if _trial_watch.is_started then
    local _trial_dropped = (_defender.has_just_been_hit and not _defender.is_being_thrown and _attacker.previous_combo >= _attacker.combo)
    _trial_dropped = _trial_dropped or _attacker.previous_combo > _attacker.combo

    if _trial_dropped or _defender.is_idle or _defender.is_wakingup or _defender.is_in_air_recovery then
      --print(string.format("%d, %d, %d, %d", to_bit(_trial_dropped), to_bit(_defender.is_idle), to_bit(_defender.is_wakingup), to_bit(_defender.is_in_air_recovery)))
      _trial_watch.is_started = false
      print(_trial_watch.hits)
    end
  end

  if _defender.has_just_been_hit then
    if not _trial_watch.is_started then
      init_trial_watch(_trial_watch)
      _trial_watch.is_started = true
    end
    table.insert(_trial_watch.hits, _attacker.animation)
  end
end

-- STEPS
function build_trial_steps(_char_moves, _hits)
  local _trial_steps = {
    steps = {},
    hit_to_step = {},
    char_moves = _char_moves
  }

  local _hit_id = 1
  while _hit_id <= #_hits do
    local _animation = _hits[_hit_id]
    table.insert(_trial_steps.steps, _animation)

    local _move = find_move_from_animation(_char_moves, _animation)
    if _move ~= nil then
      for _i = 1, #_move.hits do
        table.insert(_trial_steps.hit_to_step, #_trial_steps.steps)
        _hit_id = _hit_id + 1
      end
    else
      table.insert(_trial_steps.hit_to_step, #_trial_steps.steps)
      _hit_id = _hit_id + 1
    end
  end

  --print(_hits)
  --print(_trial_steps)

  return _trial_steps
end

function draw_trial_steps(_x, _y, _trial_steps, _progress)
  _progress = _progress or 0
  local _previous_step = 0
  for _i = 1, #_trial_steps.hit_to_step do
    local _step_id = _trial_steps.hit_to_step[_i]
    if _step_id ~= _previous_step then
      _previous_step = _step_id
      local _step = _trial_steps.steps[_step_id]
      local _s = _step
      local _move = find_move_from_animation(_trial_steps.char_moves, _step)
      if _move ~= nil then
        _s = string.format("%s - %s", _move.name, _move.command)
      end
      local _color = 0xFFFFFFFF
      if _i <= _progress then
        _color = 0xFF0000FF
      end

      gui.text(_x, _y, _s, _color)
      _y = _y + 9
    end
  end
end

-- RECORDING
function init_trial_recording(_trial_recording)
  local _object = _trial_recording or {}

  _object.on = false
  _object.char_str = ""
  _object.savestate = nil
  _object.sequence = {
    sequence = {},
    current_frame = 1
  }
  _object.steps = nil
  _object.watch = init_trial_watch()

  return _object
end

function start_trial_recording(_recording)
  init_trial_recording(_recording)

  _recording.on = true
  _recording.char_str = player_objects[1].char_str
  _recording.savestate = savestate.create(9)
  savestate.save(_recording.savestate)
end

function stop_trial_recording(_recording)
  _recording.on = false
  local _trial_definition = {
    data = {
      char = _recording.char_str,
      p1_sequence = _recording.sequence.sequence,
      hits = _recording.watch.hits,
    },
    savestate = _recording.savestate,
  }
  return _trial_definition
end

function save_trial_definition(_trial_definition, _path)
  if _trial_definition.savestate == nil then
    print(string.format("Can't save trial, no savestate found in the definition"))
    return
  end

  local _date = os.date("%Y-%m-%d_%Hh%Mm%Ss")
  local _trial_path = string.format("saved/trials/%s_%s", _trial_definition.data.char, _date);
  local _savestate_path = string.format("%s/savestate.fs", _trial_path)

  if not create_directory(_trial_path) then
    print(string.format("Failed to create directory \"%s\"", _trial_path))
    return
  end

  savestate.load(_trial_definition.savestate)
  local _savestate = savestate.create(_savestate_path)
  savestate.save(_savestate)
  if _savestate == nil or not do_file_exists(_savestate_path) then
    print(string.format("Failed to create savestate at \"%s\"", _savestate_path))
    return
  end

  local _trial_data = _trial_definition.data
  _trial_data.version = 1
  local _data_path = string.format("%s/data.json", _trial_path)
  if not write_object_to_json_file(_trial_data, _data_path) then
    print(string.format("Failed to write \"%s\"", _data_path))
    return
  end

  print(string.format("Saved trial to \"%s\"", _trial_path))
end

-- EMU
moves = load_move_data()

trials_list, trial_details= load_trials_list(true)
current_trial = 1

trial_recording = init_trial_recording()
is_playing_demo = false

staged_trial = nil
function stage_trial(_trial_definition)
  staged_trial = {}
  staged_trial.definition = _trial_definition
  local _char_moves = moves[staged_trial.definition.data.char]
  staged_trial.steps = build_trial_steps(_char_moves, staged_trial.definition.data.hits)
  staged_trial.watch = init_trial_watch()
  savestate.load(staged_trial.definition.savestate)
  is_playing_demo = false
end

function on_start()
  local _trial_definition = load_trial_definition(trials_list[1])
  stage_trial(_trial_definition)
end

function before_frame()
  -- INPUT
  local _input = joypad.get()

  -- READ GAME STATE
  gamestate_read()

  -- WRITE GAME STATE
  local _write_game_vars_settings =
  {
    freeze = false, --is_menu_open, --Pause game when menu is open
    infinite_time = true,
    music_volume = 0,
  }
  write_game_vars(_write_game_vars_settings)

  for i = 1, #player_objects do
    local _player_obj = player_objects[i]

    -- LIFE
    if is_in_match and not is_menu_open then
      local _life = memory.readbyte(_player_obj.base + 0x9F)
      local _life_refill_delay = 1
      if _player_obj.is_idle and _player_obj.idle_time > _life_refill_delay then
        local _refill_rate = 6
        _life = math.min(_life + _refill_rate, 160)
      end
      memory.writebyte(_player_obj.base + 0x9F, _life)
      _player_obj.life = _life
    end

    -- METER
    if is_in_match and not is_menu_open and not _player_obj.is_in_timed_sa and _player_obj.is_idle then
      local _is_timed_sa = character_specific[_player_obj.char_str].timed_sa[_player_obj.selected_sa]
      local _previous_meter_count = memory.readbyte(_player_obj.meter_addr[2])
      local _previous_meter_count_slave = memory.readbyte(_player_obj.meter_addr[1])
      if _previous_meter_count ~= _player_obj.max_meter_count and _previous_meter_count_slave ~= _player_obj.max_meter_count then
        local _gauge_value = 0
        if _is_timed_sa then
          _gauge_value = _player_obj.max_meter_gauge
        end
        memory.writebyte(_player_obj.gauge_addr, _gauge_value)
        memory.writebyte(_player_obj.meter_addr[2], _player_obj.max_meter_count)
        memory.writebyte(_player_obj.meter_update_flag, 0x01)
      end
    end

    -- STUN
    if _player_obj.is_idle then
      memory.writebyte(_player_obj.stun_timer_addr, 0);
      memory.writedword(_player_obj.stun_bar_addr, 0);
    end
  end

  -- trial CHECK
  local function switch_trial(_index)
    local _list_size = #trials_list
    while (_index < 1) do
      _index = _index + _list_size
    end
    _index = ((_index - 1) % _list_size) + 1
    current_trial = _index
    local _trial_definition = load_trial_definition(trials_list[current_trial])
    stage_trial(_trial_definition)
  end

  -- Reset trial
  if P1.input.pressed["coin"] then
    switch_trial(current_trial)
  end

  -- -- RECORDING
  -- if P1.input.pressed["coin"] then
  --   if not trial_recording.on then
  --     start_trial_recording(trial_recording)
  --   else
  --     --stop_trial_recording(trial_recording)
  --     --init_trial_watch(trial_watch)
  --     local _trial_definition = stop_trial_recording(trial_recording)
  --     stage_trial(_trial_definition)
  --   end
  -- end

  if P1.input.pressed["start"] then
    -- Bring up trials menu
    if is_menu_open then
      is_menu_open = false
    else
      -- Hide move list
      menu_stack_push(main_menu)
      is_menu_open = true
    end
  end

  -- Draw Menu
  if is_menu_open then
    local _horizontal_autofire_rate = 4
    local _vertical_autofire_rate = 4

    local _current_entry = menu_stack_top():current_entry()
    if _current_entry ~= nil and _current_entry.autofire_rate ~= nil then
      _horizontal_autofire_rate = _current_entry.autofire_rate
    end

    local _input =
    {
      down = check_input_down_autofire(player_objects[1], "down", _vertical_autofire_rate),
      up = check_input_down_autofire(player_objects[1], "up", _vertical_autofire_rate),
      left = check_input_down_autofire(player_objects[1], "left", _horizontal_autofire_rate),
      right = check_input_down_autofire(player_objects[1], "right", _horizontal_autofire_rate),
      validate = P1.input.pressed.LP,
      reset = P1.input.pressed.MP,
      cancel = P1.input.pressed.LK,
    }

    menu_stack_update(_input)

    menu_stack_draw()
  end

  gui.box(0, 0, 0, 0, 0, 0) -- if we don't draw something, what we drawed from last frame won't be cleared

  -- WATCH
  if trial_recording.on then
    update_trial_watch(trial_recording.watch, player_objects[1], player_objects[2])
    record_frame_input(player_objects[1], _input, trial_recording.sequence.sequence)
    trial_recording.steps = build_trial_steps(moves[player_objects[1].char_str], trial_recording.watch.hits)
  else
    update_trial_watch(staged_trial.watch, player_objects[1], player_objects[2])
  end

  -- DEMO
  if is_playing_demo then
    process_input_sequence(player_objects[1], staged_trial.sequence, _input, false)
    joypad.set(_input)

    if staged_trial.sequence.current_frame > #staged_trial.sequence.sequence then
      savestate.load(staged_trial.definition.savestate)
      is_playing_demo = false
      init_trial_watch(staged_trial.watch)
    end
  end

  if hotkey4_pressed then
    save_trial_definition(staged_trial.definition)
  end
end

-- TODO: Play demo doesn't work
function play_demo()
  load_trial()
  is_menu_open = false
  savestate.load(staged_trial.definition.savestate)
  staged_trial.sequence = {
    current_frame = 1,
    sequence = staged_trial.definition.data.p1_sequence
  }
  is_playing_demo = true
  init_trial_watch(staged_trial.watch)
end

function load_trial()
  local _path_to_trial = "data/sfiii3nr1/trials/base/" .. characters[trial_settings.character_selected] .. "/" .. trial_details[trial_settings.character_selected][trial_settings.character_trial_selected].trial_name
  local _trial_definition = load_trial_definition(_path_to_trial)
  stage_trial(_trial_definition)
end

trial_settings = {
  character_selected = 1, --First character is default
  character_trial_selected = 1, --First trial is default
  replay_pause_enabled = false,
  replay_random_hold_time_remaining = 0,
}

-- Main Menu
-- TODO: Button presses in menu (play demo, load trial) cause characters to attack when resumeing game
main_menu = make_multitab_menu(
--23, 15, 360, 195, -- screen size 383,223
  23, 5, 360, 205,  -- screen size 383,223
  {
    {
      name = "Trials",
      entries = {
        list_menu_item("Character", trial_settings, "character_selected", characters, 1, "character_trial_selected"),
        sub_list_menu_item("Trial", trial_settings, "character_trial_selected", trial_details, "character_selected", "trial_name"),
        button_menu_item("Load Trial", load_trial),
        button_menu_item("Play Demo", play_demo),
        empty_menu_item(),
        sub_text_menu_item("Description", trial_settings, "character_selected", "character_trial_selected", trial_details, "trial_description"),
      }
    },
  },
  function()
    -- Empty function on menu exit
  end,
  function(_menu)
    -- Empty function for additional draw
  end
)

function on_gui()
  local _max_hit = 0
  if not trial_recording.on then
    for _i = 1, #staged_trial.watch.hits do
      if staged_trial.watch.hits[_i] == staged_trial.definition.data.hits[_i] then
        _max_hit = _max_hit + 1
      else
        break
      end
    end
  end

  local _x = 50
  local _y = 35
  local _steps = nil
  if trial_recording.on then
    _steps = trial_recording.steps
  elseif staged_trial ~= nil then
    _steps = staged_trial.steps
  end

  if _steps ~= nil then
    -- If menu is open, then hide steps
    if not is_menu_open then
      draw_trial_steps(_x, _y, _steps, _max_hit)
    end
  end

  -- RECORDING
  if trial_recording.on then
    gui.text(5, 5, "Recording trial...")
  end

  if is_playing_demo then
    gui.text(5, 5, "Demo...")
  end

  gui.box(0, 0, 0, 0, 0, 0) -- if we don't draw something, what we drawed from last frame won't be cleared

  -- clear input state
  hotkey1_pressed = false
  hotkey2_pressed = false
  hotkey3_pressed = false
  hotkey4_pressed = false
  hotkey5_pressed = false
end

emu.registerstart(on_start)
emu.registerbefore(before_frame)
gui.register(on_gui)
