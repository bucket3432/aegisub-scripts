--[[--
  Aegs template utils. Contains utilities for interacting with
  aegs-format templates in Aegisub.

  It requires the aegsc executable in PATH.
]]

script_name = "Aegs template utils"
script_description = "Utilities to work with the aegs template format"
script_author = "bucket3432"
script_version = "0.1.0"
script_namespace = "bucket.Aegs"

local tr = aegisub.gettext
local util = require 'aegisub.util'

local haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
local petzku
if haveDepCtrl then
  depctrl = DependencyControl {
    {
      {"petzku.util", version="0.2.0", url="https://github.com/petzku/Aegisub-Scripts",
        feed="https://raw.githubusercontent.com/petzku/Aegisub-Scripts/master/DependencyControl.json"},
    }
  }
  petzku = depctrl:requireModules()
else
  petzku = require "petzku.util"
end

-- -------------------------------------------------------------------
-- Constants
--

local MARKER_EFFECT = "aegs:end"

local IMPORT_UI = {
  main = {
    path_label = {
      name = "path_label",
      class = "label",
      label = tr"Path to aegs template:",
      x = 0,
      y = 0,
      width = 5,
      height = 1,
    },
    path_input = {
      name = "path_input",
      class = "edit",
      text = "",
      x = 0,
      y = 1,
      width = 15,
      height = 1,
      hint = tr"Path to aegs template",
    },
  },
}

-- -------------------------------------------------------------------
-- Helpers
--

--- Splits a string by newlines. Ignores empty lines.
-- @param str the string to split
-- @return an iterator of lines with empty lines discarded
local function split_on_newlines(str)
  return str:gmatch("[^\r\n]+")
end

--- Converts an ASS timecode to its equivalent representation in miilliseconds.
-- @param timecode the ASS timecode to convert
-- @return the equivalent representation milliseconds
local function timecode_to_ms(timecode)
  local h, m, s, cs = timecode:match("(%d+):(%d+):(%d+)%.(%d+)")
  return h * 60 * 60 + m * 60 + s * 1000 + cs * 10
end

--- Parses a raw ASS event into a line table.
-- Assumes the event is either a Dialogue or Comment event.
-- @param raw the raw ASS event
-- @return the equivalent line table
local function parse_line(raw)
  local line = {
    section = "[Events]",
    class = "dialogue",
    comment = true,
    extra = {},
  }
  local event_type, start_time, end_time
  event_type,
  line.layer,
  start_time,
  end_time,
  line.style,
  line.actor,
  line.margin_l,
  line.margin_r,
  line.margin_t,
  line.effect,
  line.text =
    raw:match("(%a+): (%d+),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(.*)")

  line.comment = event_type == "Comment"
  line.start_time = timecode_to_ms(start_time)
  line.end_time = timecode_to_ms(end_time)

  return line
end

--- Prompts the user for a file to import.
-- @return the file path to import, or nil if cancelled.
local function prompt_for_import_file()
  local proceed, values = aegisub.dialog.display(IMPORT_UI.main)
  if not proceed then return nil end

  IMPORT_UI.main.path_input.text = values.path_input
  return values.path_input
end

--- Checks if a file is readable
-- @param file the path of the file to check
-- @return true if the file is readable, or false otherwise
local function is_file_readable(file)
  local handle = io.open(file, "r")
  if handle then
    io.close()
    return true
  else
    return false
  end
end

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

--- Main function for the Import entry
-- @param subs an Aegisub subtitle object
-- @param sel the current selection
function import_main(subs, sel)
  local file = prompt_for_import_file()
  if not file then aegisub.cancel() end
  if not is_file_readable(file) then
    aegisub.log(0, tr"Could not open file for reading: " .. file)
    aegisub.cancel()
  end

  local raw_events = petzku.io.run_cmd(
    table.concat({'aegsc', '<', '"%s"'}, ' '):format(file),
    true
  )
  local lines = {}
  for line in split_on_newlines(raw_events) do
    table.insert(lines, parse_line(line))
  end

  local marker_index = find_marker(subs)
  if marker_index then
    subs.deleterange(1, marker_index - 1)
  else
    local marker = {
      section = "[Events]",
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
    table.insert(lines, marker)
  end

  subs.insert(1, table.unpack(lines))
end

local macros = {
  {tr"Import...", tr"Import an aegs-format template. Replaces any existing imports.", import_main}
}

if haveDepCtrl then
    depctrl:registerMacros(macros)
else
    for i, macro in ipairs(macros) do
        local name, desc, fun = unpack(macro)
        aegisub.register_macro(script_name .. '/' .. name, desc, fun)
    end
end
