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
    if not flags.ctrl or flags.cmd or flags.alt or flags.shift or flags.fn then
      return false
    end

    local key = hs.keycodes.map[event:getKeyCode()]
    local target = config.remapKeys[key]
    if not target or isTerminalFocused() then
      return false
    end

    return true, {
      hs.eventtap.event.newKeyEvent({ target }, key, true),
      hs.eventtap.event.newKeyEvent({ target }, key, false),
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

  local cmdAsAlt = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local flags = event:getFlags()
    if not flags.cmd or flags.ctrl or flags.alt or flags.fn then
      return false
    end

    local app = hs.application.frontmostApplication()
    if not app then
      return false
    end
    local name = config.appNameAliases[app:name()] or app:name()
    local keys = config.cmdAsAltKeys[name]
    if not keys then
      return false
    end

    local key = hs.keycodes.map[event:getKeyCode()]
    if not keys[key] then
      return false
    end

    local mods = flags.shift and { "alt", "shift" } or { "alt" }
    return true, {
      hs.eventtap.event.newKeyEvent(mods, key, true),
      hs.eventtap.event.newKeyEvent(mods, key, false),
    }
  end)
  cmdAsAlt:start()
  M.cmdAsAlt = cmdAsAlt

  local ctrlClickRemap = hs.eventtap.new({
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseUp,
    hs.eventtap.event.types.leftMouseDragged,
  }, function(event)
    local flags = event:getFlags()
    if not flags.ctrl or flags.cmd or flags.alt or flags.shift or flags.fn then
      return false
    end

    local app = hs.application.frontmostApplication()
    if not (app and config.mouseTabApps[app:name()]) then
      return false
    end

    event:setFlags({ cmd = true })
    return false
  end)
  ctrlClickRemap:start()
  M.ctrlClickRemap = ctrlClickRemap
end

function M.isTerminalFocused()
  return terminalFocused and terminalFocused() or false
end

return M
