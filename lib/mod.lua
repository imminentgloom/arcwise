-- Arcwise mod
-- arc param mapper
-- with pages, scaling and filtering
--
-- v0.1
-- @alanza

local mod = require("core/mods")
local A = require(_path.code .. "arcwise/lib/arcwise")
local Arc_Map = require(_path.code .. "arcwise/lib/arc_map")
local Mod_Menu = require(_path.code .. "arcwise/lib/mod_menu")
local Arcwise = {
  enabled = false,
  state = {
    script_delta = function(...) end
  }
}

local function set_arcwise_enabled(x)
  if x == 2 then
    print("### attempt enabling arcwise")
    Arcwise.enabled = true
    A.arc.delta = function(n, d) A:delta(n, d) end
    Arc_Map.clear()
    Arc_Map.read()
    A:init()
    A:redraw()
  elseif x == 1 then
    print("### disabling arcwise")
    Arcwise.enabled = false
    if A.arc then
      A.arc.delta = Arcwise.state.script_delta
    end
    A:deinit()
  end
end

Mod_Menu.key_hook = function(n, z)
  if n == 1 then
    if Arcwise.enabled then
      A.shift = z == 1
      A:redraw()
    end
  end
end

Mod_Menu.redraw_hook = function()
  if not Arcwise.enabled then
    screen.level(4)
    screen.move(63, 40)
    screen.text_center("arcwise not enabled")
    screen.update()
    return true
  else
    return false
  end
end

mod.menu.register(mod.this_name, Mod_Menu)

mod.hook.register("system_post_startup", "arcwise_system_post_startup", function()
  local rebuild = _menu.rebuild_params
  _menu.rebuild_params = function()
    rebuild()
    if Mod_Menu.mode == Mod_Menu.mMAP then
      if Mod_Menu.group then
        Mod_Menu.build_sub(Mod_Menu.groupid)
      else
        Mod_Menu.build_page()
      end
    end
  end
end)

mod.hook.register("script_pre_init", "arcwise_script_pre_init", function()
  local script_init = init
  init = function()
    Arc_Map.clear()
    params:add_group("arcwise", "ARCWISE", 2)
    params:add{
      type  = "option",
      id    = "arcwise_shift_key",
      name  = "shift key",
      options = {"K1", "K2", "K3"},
      default = 1,
    }
    params:add{
      type  = "option",
      id    = "arcwise_enable",
      name  = "enabled",
      options = {"no", "yes"},
      default = 1,
      action = function() end
    }
    script_init()
    params:set_action("arcwise_enable", set_arcwise_enabled)
    A.arc = arc.connect()
    Arcwise.state.script_delta = A.arc.delta
    if A.arc.delta == nil then
      params:set("arcwise_enable", 2)
    else
      params:set("arcwise_enable", 1)
    end
  end
  local script_key = key
  key = function(n, z)
    if n == params:get("arcwise_shift_key") then A.shift = z == 1 end
    script_key(n, z)
  end
end)

mod.hook.register("script_post_cleanup", "arcwise_script_post_cleanup", function()
  A.arc = nil
  Arcwise.state.script_delta = nil
  set_arcwise_enabled(1)
  Mod_Menu.reset()
end)
