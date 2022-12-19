--[[
  Copyright (c) 2022 bucket3432

  Use of this source code is governed by an MIT-style
  license that can be found in the LICENSE file or at
  https://spdx.org/licenses/MIT.html

  SPDX-License-Identifier: MIT
]]

-- Documentation and latest sources on GitHub:
-- https://github.com/bucket3432/aegisub-scripts

--[[--
  Drop-in replacement for Aegisub's clipboard module that uses external
  programs to interface with the system clipboard.

  Requires the following external programs in `PATH`:

  * `powershell` (Windows)
  * `pbpaste` (macOS)
  * `xclip` or `xsel` (Linux and others)

  @author bucket3432
  @license MIT
  @module bucket.clipboard
]]

local haveDepCtrl, DependencyControl, depctrl = pcall(require, "l0.DependencyControl")
if haveDepCtrl then
  depctrl = DependencyControl {
    name = 'clipboard',
    version = '0.1.0',
    -- luacheck: ignore 631
    description = [[Drop-in replacement for Aegisub's clipboard module that uses external programs to interface with the system clipboard.]],
    author = "bucket3432",
    url = "https://github.com/bucket3432/aegisub-scripts",
    moduleName = 'bucket.clipboard',
  }
end

--- Gets the contents of the system clipboard.
-- @treturn string|nil The contents of the system clipboard as a string,
--   or `nil` if an error occurs or the clipboard has no contents.
local function get()
  local command
  if jit.os == "Windows" then
    command = "powershell -command Get-Clipboard"
  elseif jit.os == "OSX" then
    command = "pbpaste"
  else -- assume Linux/BSD/Other *nix with X
    command = "{ xclip -o -selection clipboard || xsel -ob; } 2>/dev/null"
  end

  local clip = io.popen(command)

  local contents = clip:read("*a")
  clip:close()

  if contents == nil or contents == "" then
    return nil
  else
    return contents
  end
end

--- Sets the contents of the system clipboard.
-- @treturn boolean `true` if the clipbard was set successfully, `false` otherwise.
local function set(
  new_text -- string: The text to set to the clipboard.
)
  local command
  if jit.os == "Windows" then
    command = "powershell -command Set-Clipboard"
  elseif jit.os == "OSX" then
    command = "pbcopy"
  else -- assume Linux/BSD/Other *nix with X
    command = "{ xclip -i -selection clipboard >&- || xsel -ib; } 2>/dev/null"
  end

  local clip = io.popen(command, 'w')
  local success, err = clip:write(new_text)
  clip:close()

  if not success then
    aegisub.log(2, err)
    return false
  else
    return true
  end
end

--- @export
local exports = {
  get = get,
  set = set
}

if haveDepCtrl then
  exports.version = depctrl
  depctrl:register(exports)
end

return exports
