--[[
  Copyright (c) 2022-2025 bucket3432

  Use of this source code is governed by an MIT-style
  license that can be found in the LICENSE file or at
  https://spdx.org/licenses/MIT.html

  SPDX-License-Identifier: MIT
]]

-- Documentation and latest sources on GitHub:
-- https://github.com/bucket3432/aegisub-scripts

--[[--
Aegs template utils. Contains utilities for interacting with
aegs-format templates in Aegisub.

## Requirements

- [petzkuLib](https://typesettingtools.github.io/depctrl-browser/modules/petzku.util/)
- [`aegsc`][aegsc] available in `PATH`

[aegsc]: https://github.com/butterfansubs/aegsc#installation

## Installation

Copy [`macros/bucket.Aegs.lua`][bucket.Aegs.lua] into `automation/autoload`
in your Aegisub user config directory.

The script will register itself with DependencyControl if it is available.

[bucket.Aegs.lua]: https://github.com/bucket3432/aegisub-scripts/raw/main/macros/bucket.Aegs.lua

@macro bucket.Aegs
]]

script_name = "Aegs template"
script_description = "Utilities to work with the aegs template format"
script_author = "bucket3432"
script_version = "0.2.0"
script_namespace = "bucket.Aegs"

local tr = aegisub.gettext

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
-- @tparam string str the string to split
-- @treturn string an iterator of lines with empty lines discarded
local function split_on_newlines(str)
  return str:gmatch("[^\r\n]+")
end

--- Converts an ASS timecode to its equivalent representation in miilliseconds.
-- @tparam string timecode the ASS timecode to convert
-- @treturn number the equivalent representation milliseconds
local function timecode_to_ms(timecode)
  local h, m, s, cs = timecode:match("(%d+):(%d+):(%d+)%.(%d+)")
  return h * 60 * 60 + m * 60 + s * 1000 + cs * 10
end

--- Parses a raw ASS event into a line table.
-- Assumes the event is either a Dialogue or Comment event.
-- @tparam string raw the raw ASS event
-- @treturn tab the equivalent line table
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
-- @treturn string the file path to import, or nil if cancelled.
local function prompt_for_import_file()
  local proceed, values = aegisub.dialog.display(IMPORT_UI.main)
  if not proceed then return nil end

  IMPORT_UI.main.path_input.text = values.path_input
  return values.path_input
end

--- Checks if a file is readable
-- @tparam string file the path of the file to check
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
-- @tparam table subs an Aegisub subtitle object
-- @return number|nil the index of the marker, or nil if not present
local function find_marker(subs)
  for i, line in ipairs(subs) do
    if line.effect == MARKER_EFFECT then
      return i
    end
  end
  return nil
end

--- Determines the index of the first dialogue line
-- @tparam table subs an Aegisub subtitle object
-- @return number|nil the index of the first dialogue line, or nil if not present
local function find_first_dialogue(subs)
  for i = 1, #subs do
    if subs[i].class == "dialogue" then
      return i
    end
  end

  return nil
end

-- -------------------------------------------------------------------
-- Main
--

--- Imports an Aegs file
-- @tparam table subs an Aegisub subtitle object
-- @tparam string file the path to the .aegs file
local function import_aegs(subs, file)
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
  local dialogue_index = find_first_dialogue(subs)
  if marker_index then
    subs.deleterange(dialogue_index, marker_index - 1)
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

  subs.insert(dialogue_index, table.unpack(lines))
end

--- Main function for the Import entry
-- @tparam table subs an Aegisub subtitle object
local function import_main(subs)
  local file = prompt_for_import_file()
  if not file then aegisub.cancel() end

  import_aegs(subs, file)
end

--- Main function for the Import (last used) entry
-- @tparam table subs an Aegisub subtitle object
local function import_last(subs)
  local file = IMPORT_UI.main.path_input.text

  if IMPORT_UI.main.path_input.text == "" then
    import_main(subs)
  else
    import_aegs(subs, file)
  end
end

local macros = {
  --- Imports an aegs-format template. Replaces any existing imports.
  --
  -- Usage:
  --
  -- 1. Save your `.aegs` template to a file.
  -- 2. Navigate to `Automation > Aegs template > Import...`.
  -- 3. Enter the full path to the `.aegs` file.
  -- 4. Click OK.
  --
  -- The compiled template should now appear at the top of the file,
  -- along with a line that has `aegs:end` in the Effect field.
  -- This line should be changed to ensure that the style exists
  -- and the times will not interfere with other tooling
  -- (e.g. SubKt, which will throw an error if shifting a line results in negative times).
  --
  -- Updates may be made in the `.aegs` template
  -- and re-imported using the same steps above.
  -- All lines up to but not including the `aegs:end` line will be deleted
  -- and replaced with the new output.
  --
  -- @menuitem import
  -- @displayname Import...
  {tr"Import...", tr"Import an aegs-format template. Replaces any existing imports.", import_main},

  --- Imports an aegs-format template using the last-used settings. Replaces any existing imports.
  --
  -- If this is the first time the script is run in the current session,
  -- you will be prompted for a file.
  -- See @{import|Import...} for details.
  --
  -- @menuitem import_last_used
  -- @displayname Import (last used)
  {tr"Import (last used)", tr"Import an aegs-format template with the last-used settings. Replaces any existing imports.", import_last}
}

if haveDepCtrl then
    depctrl:registerMacros(macros)
else
    for _, macro in ipairs(macros) do
        local name, desc, fun = unpack(macro)
        aegisub.register_macro(script_name .. '/' .. name, desc, fun)
    end
end
