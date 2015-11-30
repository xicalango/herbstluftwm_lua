#!/usr/bin/env lua

--- a set of libraries to control herbstluftwm
-- @module herbstluftwm

local command = {}
command.__index = command

local function using( resource, callback )
  local result = callback( resource )
  resource:close()
  return result
end

local function join_cmd( cmd, args, char )
  char = char or " "

  if type(args) == "string" then
    args = {args}
  end

  if #args == 0 then
    return cmd
  end

  local args_concat = table.concat( args, char )
  return cmd .. char .. args_concat
end

local function join_buttons( mod, buttons )
  return join_cmd( mod, buttons, "-" )
end

local function cmd(...)
  return command.new(...)
end

local function to_signed_string(number)
  if number > 0 then
    return "+" .. tostring(number)
  else
    return tostring(number)
  end
end

--- creates a new command builder for the given cmd
-- @param cmd command name
-- @return a new command builder
function command.new(cmd, ignore_error)
  local self = {}
  setmetatable( self, command )

  self.cmd = cmd
  self.args = {}
  self.ignore_error = ignore_error

  return self
end

--- iterate the args list and add each element as an argument
function command:all_args( args )
  for _, arg in ipairs(args) do
    self:arg( arg )
  end

  return self
end

--- add the given argument
-- @param arg the argument to add
-- @param quote if not false then add quotes around the argument
function command:arg(arg, quote)
  if arg == nil then
    return self
  end

  if quote then
    arg = '"' .. arg .. '"'
  end
  table.insert( self.args, arg )
  return self
end

--- shortcut to command:arg(arg, true)
-- @see command:arg
function command:arg_quote(arg)
  return self:arg(arg, true)
end

function command:cmd_arg( command )
  return self:arg( command:build() )
end

function command:build()
  return join_cmd( self.cmd, self.args )
end

function command:build_list()
  local cmds = { self.cmd }

  for _, v in ipairs( self.args ) do
    table.insert( cmds, v )
  end

  return cmds
end


local hwm = {}
hwm.__index = hwm
hwm.LOG = false
hwm.DEBUG = false
hwm.herbstclient = "herbstclient"
hwm.mod = "Mod4"
hwm.split_factor = 0.5
hwm.resize_step = 0.05

function hwm.new(init)
  init = init or {}
  setmetatable( init, hwm )

  return init
end

function hwm:hc( args, ignore_error )
  if self.DEBUG then
    local args_concat = table.concat( args, "' '" )
    local cmd = self.herbstclient .. " '" .. args_concat .. "'"

    print(cmd)
    return ""
  else
    local cmd = join_cmd( self.herbstclient, args )

    if hwm.LOG then print(cmd) end

    local p = assert(io.popen(cmd, "r"))
    local content = p:read("*all")
    local status = p:close()

    if ignore_error then
      return content, status
    else
      assert(status)
      return content
    end
  end
end

function hwm:run( cmd )
  return self:hc( cmd:build_list(), cmd.ignore_error )
end

function hwm:run_all( cmds )
  for i, cmd in ipairs(cmds) do
    self:hc( cmd:build_list(), cmd.ignore_error )
  end
end

function hwm:emit_hook( arguments )
  return cmd("emit_hook"):all_args( arguments )
end

function hwm:keyunbind( buttons )
  if type(buttons) == "table" then
    buttons = join_buttons( self.mod, buttons )
  end

  return cmd("keyunbind"):arg( buttons )
end

function hwm:mouseunbind( arg )
  return cmd("mouseunbind"):arg( arg )
end

function hwm:keybind( buttons, command )
  local all_buttons = join_buttons( self.mod, buttons )
  return cmd("keybind")
    :arg(all_buttons)
    :cmd_arg(command)
end

function hwm:cmd( _cmd, ... )
  return cmd(_cmd, ...)
end

function hwm:spawn( run_cmd )
  local success, build_cmd = pcall(run_cmd.build, run_cmd)

  if success then
    run_cmd = build_cmd
  end

  return cmd("spawn"):arg( run_cmd )
end

function hwm:reload()
  return cmd("reload")
end

function hwm:close()
  return cmd("close")
end

function hwm:focus(dir)
  return cmd("focus"):arg( dir )
end

function hwm:shift(dir)
  return cmd("shift"):arg( dir )
end

function hwm:split( dir, factor )
  factor = factor or self.split_factor
  return cmd("split"):arg(dir):arg(factor)
end

function hwm:explode()
  return cmd("split"):arg("explode")
end

function hwm:resize(dir, step)
  step = step or self.resize_step
  return cmd("resize"):arg(dir):arg( to_signed_string( step ) )
end

function hwm:add_tag(name)
  return cmd("add"):arg_quote(name)
end

function hwm:use_tag(name)
  return cmd("use"):arg_quote(name)
end

function hwm:move_to_tag(name)
  return cmd("move"):arg_quote(name)
end

function hwm:load_tag_config(name, config)
  return cmd("load"):arg_quote(name):arg_quote(config)
end

function hwm:load_tag_config_from_file(name, config_path)
  local content = using( assert(io.open(config_path, "r")), function(f)
    return f:read("*all")
  end)

  return self:load_tag_config( name, content )
end

function hwm:step_index( step )
  return self:use_index( to_signed_string( step ) )
end

function hwm:use_index( index, args )
  args = args or {}
  return cmd("use_index"):arg(index):all_args( args )
end

function hwm:remove()
  return cmd("remove")
end

function hwm:cycle_layout( dir )
  dir = dir or 1
  return cmd("cycle_layout"):arg(dir)
end

function hwm:floating(mode)
  mode = mode or "toggle"
  return cmd("floating"):arg(mode)
end

function hwm:fullscreen(mode)
  mode = mode or "toggle"
  return cmd("fullscreen"):arg(mode)
end

function hwm:pseudotile(mode)
  mode = mode or "toggle"
  return cmd("pseudotile"):arg(mode)
end

function hwm:mousebind( index, command )
  return cmd("mousebind")
    :arg(self.mod .. "-Button" .. index)
    :cmd_arg(command)
end

function hwm:mouse_move()
  return cmd("move")
end

function hwm:mouse_resize()
  return cmd("resize")
end

function hwm:mouse_zoom()
  return cmd("zoom")
end

function hwm:mouse_call( command )
  return cmd("call"):cmd_arg( command )
end

function hwm:cycle_monitor()
  return cmd("cycle_monitor")
end

function hwm:cycle( dir )
  return cmd("cycle"):arg( to_signed_string(dir) )
end

function hwm:cycle_all( dir )
  return cmd("cycle_all"):arg( to_signed_string(dir) )
end

function hwm:set(variable, value)
  return cmd("set"):arg(variable):arg_quote(value)
end

function hwm:attr(variable, value)
  return cmd("attr"):arg(variable):arg(value)
end

function hwm:unrule( arg )
  return cmd("unrule"):arg( arg )
end

function hwm:rule( args )
  return cmd("rule"):all_args( args )
end

function hwm:unlock()
  return cmd("unlock")
end

function hwm:detect_monitors()
  return cmd("detect_monitors")
end

function hwm:rename( old_name, new_name )
  return cmd("rename"):arg(old_name):arg(new_name)
end

function hwm:tag_status( monitor )
  return cmd("tag_status"):arg(monitor)
end

local hwm_utils = {}
hwm_utils.__index = hwm_utils

function hwm_utils.new( hwm_inst )
  local self = {}
  setmetatable( self, hwm_utils )

  self.hwm = hwm_inst or hwm.new()

  return self
end

hwm_utils.DIRECTIONS = { "left", "down", "up", "right" }
hwm_utils.DEFAULT_MOVE_KEYS = {
  left  = {"Left", "h"},
  down  = {"Down", "j"},
  up    = {"Up", "k"},
  right = {"Right", "l"}
}
hwm_utils.DEFAULT_MOVE_MOD = "Shift"
hwm_utils.DEFAULT_RESIZE_MOD = "Control"

local mod_key = {}

function mod_key.__add( mod_table, key )
  table.insert( mod_table, key )
  return mod_table
end

function mod_key.new( key )
  local self = {key}
  setmetatable(self, mod_key)
  return self
end

function hwm_utils:shift()
  return mod_key.new( "Shift" )
end

function hwm_utils:control()
  return mod_key.new( "Control" )
end

function hwm_utils:get_tag_status( monitor )
  local status_line = self.hwm:run( self.hwm:tag_status( monitor ) )

  local tag_status_table = {}

  for status in string.gmatch( status_line, '([^\t]+)') do
    local tag_status = {}

    tag_status.status_char = string.sub( status, 1, 1 )
    tag_status.tag_name = string.sub( status, 2 )

    if tag_status.status_char == "." then
      tag_status.status = "empty"
    elseif tag_status.status_char == ":" then
      tag_status.status = "not_empty"
    elseif tag_status.status_char == "+" then
      tag_status.status = "viewed_not_focused"
      tag_status.monitor = monitor or "same"
    elseif tag_status.status_char == "#" then
      tag_status.status = "viewed_and_focused"
      tag_status.monitor = monitor or "same"
    elseif tag_status.status_char == "-" then
      tag_status.status = "viewed_not_focused"
      tag_status.monitor = "different"
    elseif tag_status.status_char == "%" then
      tag_status.status = "viewed_and_focused"
      tag_status.monitor = "different"
    elseif tag_status.status_char == "!" then
      tag_status.status = "urgent"
    end

    if tag_status.status ~= nil then
      table.insert( tag_status_table, tag_status )
    end
  end

  return tag_status_table
end

function hwm_utils:setup_keybindings( keybindings )
  for _, kb in ipairs(keybindings) do
    self.hwm:run( self.hwm:keybind( kb.keys, kb.cmd ) )
  end
end

function hwm_utils:keybind( keys, cmd )
  return {keys=keys, cmd=cmd}
end

function hwm_utils:setup_mousebindings( mousebindings )
  for mouses, cmd in pairs(mousebindings) do
    self.hwm:run( self.hwm:mousebind( mouses, cmd ) )
  end
end

function hwm_utils:setup_directional( move_keys, callback )
  move_keys = move_keys or hwm_utils.DEFAULT_MOVE_KEYS
  for _, dir in ipairs(hwm_utils.DIRECTIONS) do
    for _, key in ipairs(move_keys[dir]) do
      callback( key, dir )
    end
  end
end

function hwm_utils:setup_movement( move_keys, move_modifier )
  move_modifier = move_modifier or hwm_utils.DEFAULT_MOVE_MOD

  self:setup_directional( move_keys, function( key, dir)
      self.hwm:run_all {
        self.hwm:keybind( {key}, self.hwm:focus( dir ) ),
        self.hwm:keybind( {move_modifier, key}, self.hwm:shift( dir ) )
      }
  end)
end

function hwm_utils:setup_resizing( resize_keys, resize_modifier )
  resize_modifier = resize_modifier or hwm_utils.DEFAULT_RESIZE_MOD
  self:setup_directional( resize_keys, function( key, dir )
    self.hwm:run( self.hwm:keybind( {resize_modifier, key}, self.hwm:resize( dir ) ) )
  end)
end

function hwm_utils:tag( tag, key )
  return {tag = tag, key = key}
end

function hwm_utils:setup_tags(tag_config, default_tag)
  if default_tag ~= nil then
    local rename_cmd = self.hwm:rename( "default", default_tag )
    rename_cmd.ignore_error = true
    self.hwm:run( rename_cmd )
  end

  for _, cfg in pairs(tag_config) do
    local add_cmd = self.hwm:add_tag(cfg.tag)
    local use_cmd = self.hwm:use_tag(cfg.tag)
    local move_cmd = self.hwm:move_to_tag(cfg.tag)

    self.hwm:run_all { 
      add_cmd,
      self.hwm:keybind( {cfg.key}, use_cmd ),
      self.hwm:keybind( {"Shift", cfg.key}, move_cmd ) -- TODO make shift configurable
    }

  end
end

function hwm_utils:reset()
  self.hwm:run_all {
    self.hwm:emit_hook{ "reload" },
    self.hwm:keyunbind( "--all" ),
    self.hwm:mouseunbind( "--all" )
  }
end

return {
  hwm = hwm, 
  hwm_utils = hwm_utils
}
