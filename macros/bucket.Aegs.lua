script_name = "Aegs template utils"
script_description = "Utilities to work with the aegs template format"
script_author = "bucket3432"
script_version = "0.1.0"
script_namespace = "bucket.Aegs"

local tr = aegisub.gettext

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

function import_main(subs, sel)
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
