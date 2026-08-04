local spaces = require("modules.spaces")
local tiling = require("modules.tiling")
local apps = require("modules.apps")
local keyboard = require("modules.keyboard")
local status = require("modules.status")

hs.window.animationDuration = 0

spaces.start()
tiling.start()
apps.start()
keyboard.start()
status.start()
