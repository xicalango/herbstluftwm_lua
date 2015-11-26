#!/usr/bin/env lua

local command = {}
command.__index = command

local function cmd(cmd)
  return command.new(cmd)
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


function command:args( args )
  for _, arg in ipairs(args) do
    self:arg( arg )
  end
end

function command:arg(arg, quote)
  if quote then
    arg = '"' .. arg .. '"'
  end
  table.insert( self.args, arg )
  return self
end

function command:arg_quote(arg)
  return self:arg(arg, true)
end

function command:command( command )
  return self:arg( command:get_cmd() )
end

function command:get_cmd()
  if #self.args == 0 then
    return self.cmd
  end

  local args_concat = table.concat( self.args, " " )
  return self.cmd .. " " .. args_concat
end

function command:get_cmds()
  local cmds = {}
  table.insert( cmds, self.cmd )
  for _,v in ipairs(self.args) do
    table.insert( cmds, v )
  end
  return cmds
end


local hwm = {}
hwm.__index = hwm
hwm.HERBSTCLIENT = "herbstclient"
hwm.MOD = "Mod4"
hwm.SPLIT_FACTOR = 0.5
hwm.RESIZE_STEP = 0.05

function hwm.new(init)
  local self = {}
  setmetatable( self, hwm )

  init = init or {}
  self.herbstclient = init.herbstclient or hwm.HERBSTCLIENT
  self.mod = init.mod or hwm.MOD
  self.split_factor = init.split_factor or hwm.SPLIT_FACTOR
  self.resize_step = init.resize_step or hwm.RESIZE_STEP

  return self
end

function hwm:hc(args)
  local args_concat = table.concat( args, "' '" )
  local cmd = self.herbstclient .. " '" .. args_concat .. "'"

  print(cmd)
end

function hwm:run_all( cmds )
  for _, cmd in ipairs(cmds) do
    self:hc(cmd:get_cmds())
  end
end

function hwm:reset()
  self:run_all {
    cmd("emit_hook"):arg("reload"),
    cmd("keyunbind"):arg("--all"),
    cmd("mouseunbind"):arg("--all")
  }
end

function hwm:keybind( buttons, command )
  local all_buttons = self.mod .. "-" .. table.concat( buttons, "-" )
  return cmd("keybind")
    :arg(all_buttons)
    :command(command)
end

function hwm:emit_hook( hooks )
  return cmd(
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

local function to_signed_string(number)
  if number > 0 then
    number = "+" .. tostring(number)
  else
    number = tostring(number)
  end
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
  error("unimplemented")
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
    :command(command)
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

