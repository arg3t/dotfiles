local config = require("config")

local M = {}
local terminalFocused

local function appIsTerminal(app)
  if not app then
    return false
  end
  local bundle = app.bundleID and app:bundleID()
  if bundle and config.terminalBundles[bundle] then
    return true
  end
  return config.terminalApps[app:name()] == true
end

local function isTerminalFocused()
  if appIsTerminal(hs.application.frontmostApplication()) then
    return true
  end
  local win = hs.window.focusedWindow()
  return appIsTerminal(win and win:application())
end

local function modsMatch(flags, wanted)
  local want = { ctrl = true }
  for _, m in ipairs(wanted) do
    want[m] = true
  end
  for _, m in ipairs({ "cmd", "alt", "shift", "fn" }) do
    if (flags[m] and true or false) ~= (want[m] and true or false) then
      return false
    end
  end
  return flags.ctrl == true
end

function M.start()
  terminalFocused = isTerminalFocused

  local ctrlRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local flags = event:getFlags()
    -- fn is deliberately not rejected: macOS classes the arrow keys as function keys
    -- and sets fn on their events, so testing it here would skip ctrl+left/right.
    if not flags.ctrl or flags.cmd or flags.alt or flags.shift then
      return false
    end

    local key = hs.keycodes.map[event:getKeyCode()]
    local target = config.remapKeys[key]
    if not target or isTerminalFocused() then
      return false
    end

    local mods = { target }
    if flags.fn then
      mods[#mods + 1] = "fn"
    end

    return true, {
      hs.eventtap.event.newKeyEvent(mods, key, true),
      hs.eventtap.event.newKeyEvent(mods, key, false),
    }
  end)
  ctrlRemap:start()
  M.ctrlRemap = ctrlRemap

  local appCtrlRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local flags = event:getFlags()
    if not flags.ctrl then
      return false
    end

    local app = hs.application.frontmostApplication()
    if not app then
      return false
    end
    local name = config.appNameAliases[app:name()] or app:name()
    local rules = config.appKeyRemaps[name]
    if not rules then
      return false
    end

    local key = hs.keycodes.map[event:getKeyCode()]
    for _, rule in ipairs(rules) do
      if key == rule.from[2] and modsMatch(flags, rule.from[1]) then
        return true, {
          hs.eventtap.event.newKeyEvent(rule.to[1], rule.to[2], true),
          hs.eventtap.event.newKeyEvent(rule.to[1], rule.to[2], false),
        }
      end
    end

    return false
  end)
  appCtrlRemap:start()
  M.appCtrlRemap = appCtrlRemap

  local cmdRemap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local flags = event:getFlags()
    -- fn is not rejected here either; see ctrlRemap above.
    if not flags.cmd or flags.ctrl or flags.alt then
      return false
    end

    local app = hs.application.frontmostApplication()
    if not app then
      return false
    end
    local name = config.appNameAliases[app:name()] or app:name()
    local keys = config.cmdRemapKeys[name]
    if not keys then
      return false
    end

    local key = hs.keycodes.map[event:getKeyCode()]
    local target = keys[key]
    if not target then
      return false
    end

    local mods = { target }
    if flags.shift then
      mods[#mods + 1] = "shift"
    end
    if flags.fn then
      mods[#mods + 1] = "fn"
    end

    return true, {
      hs.eventtap.event.newKeyEvent(mods, key, true),
      hs.eventtap.event.newKeyEvent(mods, key, false),
    }
  end)
  cmdRemap:start()
  M.cmdRemap = cmdRemap

  local ctrlMouseRemap = hs.eventtap.new({
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseUp,
    hs.eventtap.event.types.leftMouseDragged,
    hs.eventtap.event.types.scrollWheel,
  }, function(event)
    local flags = event:getFlags()
    if not flags.ctrl or flags.cmd or flags.fn then
      return false
    end

    local app = hs.application.frontmostApplication()
    if not app then
      return false
    end
    local scope = config.ctrlMouseAsCmdApps[config.appNameAliases[app:name()] or app:name()]
    if not scope then
      return false
    end
    if scope ~= "all" and event:getType() == hs.eventtap.event.types.scrollWheel then
      return false
    end

    -- Replace the flags rather than adding cmd: dropping ctrl is what stops AppKit
    -- from turning a ctrl+click into a secondary click / context menu. alt and shift
    -- ride along so ctrl+alt+click still maps to "open definition to the side".
    local out = { cmd = true }
    if flags.alt then
      out.alt = true
    end
    if flags.shift then
      out.shift = true
    end
    event:setFlags(out)
    return false
  end)
  ctrlMouseRemap:start()
  M.ctrlMouseRemap = ctrlMouseRemap
end

function M.isTerminalFocused()
  return terminalFocused and terminalFocused() or false
end

return M
