local config = require("config")

local M = {}

local function binPath(name)
  local candidates = {
    os.getenv("HOME") .. "/.nix-profile/bin/" .. name,
    "/run/current-system/sw/bin/" .. name,
    "/etc/profiles/per-user/" .. (os.getenv("USER") or "") .. "/bin/" .. name,
    "/opt/homebrew/bin/" .. name,
  }
  for _, path in ipairs(candidates) do
    if hs.fs.attributes(path) then
      return path
    end
  end
  return nil
end

function M.run(name, args)
  local bin = binPath(name)
  if not bin then
    hs.alert.show(name .. " not found")
    return
  end
  local task = hs.task.new(bin, nil, args)
  task:setWorkingDirectory(os.getenv("HOME"))
  task:start()
end

function M.start()
  hs.hotkey.bind(config.mod, "s", function()
    M.run("kitten", { "quick-access-terminal" })
  end)

  hs.hotkey.bind(config.mod, "x", function()
    hs.caffeinate.lockScreen()
  end)

  hs.hotkey.bind(config.mod, "return", function()
    M.run("kitty", { "--single-instance", "--directory", os.getenv("HOME") })
    hs.timer.doAfter(0.3, function()
      local app = hs.application.get("kitty")
      if app then
        app:activate()
      end
    end)
  end)
end

return M
