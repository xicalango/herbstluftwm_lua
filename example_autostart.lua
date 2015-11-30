#!/usr/bin/env lua

package.path = debug.getinfo(1,"S").source:match[[^@?(.*[\/])[^\/]-$]] .."?.lua;".. package.path

local hwm = require("herbstluftwm")

local h = hwm.hwm.new()
local hu = hwm.hwm_utils.new( h )

hu:reset()

-- setup basics

hu:setup_movement()
hu:setup_resizing()

-- wm management
hu:setup_keybindings {
  hu:keybind({"Shift", "r"}, h:reload()),
  hu:keybind({"Shift", "q"}, h:close())
}

-- applications
hu:setup_keybindings {
  hu:keybind("Return", h:spawn( "urxvt" )),
  hu:keybind({"Shift", "Return"}, h:spawn( h:cmd("chromium"):arg("--touch-devices=123"))),
  hu:keybind("d", h:spawn( h:cmd("dmenu_run") )),
}

-- splits

hu:setup_keybindings {
  hu:keybind("u", h:split( "bottom" )),
  hu:keybind("o", h:split( "right" )),
  hu:keybind({"Control", "space"}, h:explode())
}

-- setup tags
local tags = {
  hu:tag( "shell", "1" ),
  hu:tag( "internet", "2" ),
  hu:tag( "comm", "3" ),
  hu:tag( "doc", "4" ),
  hu:tag( "dev", "F1" ),
  hu:tag( "VNC", "F2" )
}

hu:setup_tags( tags, "shell" )

-- cycle through tags
hu:setup_keybindings{
  hu:keybind("period", h:use_index( "+1", {"--skip-visible"} )),
  hu:keybind("comma", h:use_index( "-1", {"--skip-visible"} ))
}

-- layouting
hu:setup_keybindings{
  hu:keybind("r", h:remove()),
  hu:keybind("space", h:cycle_layout()),
  hu:keybind("s", h:floating()),
  hu:keybind("f", h:fullscreen()),
  hu:keybind("p", h:pseudotile())
}

-- mouse
hu:setup_mousebindings{
  ["1"] = h:mouse_move(),
  ["2"] = h:mouse_zoom(),
  ["3"] = h:mouse_resize()
}

-- focus

hu:setup_keybindings{
  hu:keybind("BackSpace", h:cycle_monitor()),
  hu:keybind("Tab", h:cycle( 1 )),
  hu:keybind({"Shift", "Tab"}, h:cycle( -1 )),
  hu:keybind("c", h:cycle_all( 1 )),
  hu:keybind({"Shift", "c"}, h:cycle_all( -1 ))
}


