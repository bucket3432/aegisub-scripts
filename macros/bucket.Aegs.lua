script_name = "Aegs template utils"
script_description = "Utilities to work with the aegs template format"
script_author = "bucket3432"
script_version = "0.1.0"
script_namespace = "bucket.Aegs"

local tr = aegisub.gettext
local util = require 'aegisub.util'

local haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
local ConfigHandler, config, petzku
if haveDepCtrl then
  depctrl = DependencyControl {
    {
      {"petzku.util", version="0.2.0", url="https://github.com/petzku/Aegisub-Scripts"},
      {"a-mo.ConfigHandler", version="1.1.4", url="https://github.com/TypesettingTools/Aegisub-Motion",
        feed="https://raw.githubusercontent.com/TypesettingTools/Aegisub-Motion/DepCtrl/DependencyControl.json"},
    }
  }
  petzku, ConfigHandler = depctrl:requireModules()
else
  petzku = require "petzku.util"
end

local MARKER_EFFECT = "aegs:end"

-- -------------------------------------------------------------------
-- Helpers
--

--- Determines the index of the aegs:end marker
-- The marker is a dialogue line that contains aegs:end
-- in the effect field.
-- @param subs an Aegisub subtitle object
-- @return the index of the marker, or nil if not present
local function find_marker(subs)
  for i, line in ipairs(subs) do
    if line.effect == MARKER_EFFECT then
      return i
    end
  end
  return nil
end

-- -------------------------------------------------------------------
-- Main
--

function import_main(subs, sel)
  local marker_index = find_marker(subs)
  if marker_index then
    subs.deleterange(1, marker_index - 1)
  else
    local marker = {
      class = "dialogue",
      comment = true,
      layer = 0,
      start_time = 0,
      end_time = 0,
      style = "Default",
      actor = "",
      margin_l = 0,
      margin_r = 0,
      margin_t = 0,
      effect = MARKER_EFFECT,
      text = "",
      extra = {},
    }
    subs.insert(1, marker)
  end
end

local macros = {
  {tr"Import", tr"Import an aegs-format template. Replaces any existing imports.", import_main}
}

if haveDepCtrl then
    --table.insert(macros, {tr'Config', tr'Open configuration menu', show_config_dialog})
    depctrl:registerMacros(macros)
else
    for i, macro in ipairs(macros) do
        local name, desc, fun = unpack(macro)
        aegisub.register_macro(script_name .. '/' .. name, desc, fun)
    end
end
