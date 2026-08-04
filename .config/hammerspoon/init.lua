-- Window layout and workspaces are owned by AeroSpace (services.aerospace in
-- nix/hosts/vela.nix). Hammerspoon keeps only the input remaps and helpers.
local apps = require("modules.apps")
local keyboard = require("modules.keyboard")
local status = require("modules.status")

apps.start()
keyboard.start()
status.start()
