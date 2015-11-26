#!/usr/bin/env lua

--- a set of libraries to control herbstluftwm
-- @module herbstluftwm

local DEBUG = true

local command = {}
command.__index = command

local function using( resource, callback )
  local result = callback( resource )
  resource:close()
  return result
end

local function join_cmd( cmd, args, char )
  char = char or " "
  if #args == 0 then
    return cmd
  end

  local args_concat = table.concat( args, char )
  return cmd .. " " .. args_concat
end

local function join_buttons( mod, buttons )
  return join_cmd( mod, buttons, "-" )
end

local function cmd(cmd)
  return command.new(cmd)
end

local function to_signed_string(number)
  if number > 0 then
    number = "+" .. tostring(number)
  else
    number = tostring(number)
  end
end

--- creates a new command builder for the given cmd
-- @param cmd command name
-- @return a new command builder
function command.new(cmd)
  local self = {}
  setmetatable( self, command )

  self.cmd = cmd
  self.args = {}

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
    return
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
hwm.herbstclient = "herbstclient"
hwm.mod = "Mod4"
hwm.split_factor = 0.5
hwm.resize_step = 0.05

function hwm.new(init)
  init = init or {}
  setmetatable( init, hwm )

  return init
end

function hwm:hc( args )
  if DEBUG then
    local args_concat = table.concat( args, "' '" )
    local cmd = self.herbstclient .. " '" .. args_concat .. "'"

    print(cmd)
  else
    local cmd = join_cmd( self.herbstclient, args )

    os.execute(cmd)
  end
end

function hwm:run_all( cmds )
  for i, cmd in ipairs(cmds) do
    self:hc( cmd:build_list() )
  end
end


function hwm:reset()
  self:run_all {
    self:emit_hook{ "reload" },
    self:keyunbind( "--all" ),
    self:mouseunbind( "--all" )
  }
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

function hwm:spawn( run_cmd )
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

function hwm:use_index( index )
  return cmd("use_index"):arg(index)
end

function hwm:remove()
  return cmd("remove")
end

function hwm:cycle_layout(dir)
  dir = dir or 1
  return cmd("cycle_layout"):arg(1)
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

function hwm:set(variable, value)
  return cmd("set"):arg(variable):arg_quote(value)
end

function hwm:attr(variable, value)
  return cmd("attr"):arg(variable):arg(value)
end

function hwm:setup_tags(tag_config)
  for _, cfg in pairs(tag_config) do
    local add_cmd = self:add_tag(cfg.tag)
    local use_cmd = self:use_tag(cfg.tag)
    local move_cmd = self:move_to_tag(cfg.tag)

    self:run_all { 
      add_cmd,
      self:keybind( {cfg.key}, use_cmd ),
      self:keybind( {"Shift", cfg.key}, move_cmd )
    }

  end
end

function hwm.tag(tag, key)
  return {tag = tag, key = key}
end

h = hwm.new()
h:reset()

h:run_all {
  h:keybind( {"Shift", "e"}, h:spawn( "/home/alexx/.config/herbstluftwm/nagquit.sh" ) ),
  h:keybind( {"Shift", "r"}, h:reload() ),
  h:keybind( {"Shift", "q"}, h:close() ),
  h:keybind( {"Return"}, h:spawn( "urxvt" ) ),
  h:keybind( {"Left"}, h:focus( "left" ) )
}

h:setup_tags {
  h.tag( "shell", "1" ),
  h.tag( "internet", "2" ),
  h.tag( "comm", "3" ),
  h.tag( "doc", "F1" )
}

