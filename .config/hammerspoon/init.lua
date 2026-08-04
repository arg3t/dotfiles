local spaces = require("modules.spaces")
local snapping = require("modules.snapping")
local apps = require("modules.apps")
local keyboard = require("modules.keyboard")
local status = require("modules.status")

hs.window.animationDuration = 0

spaces.start()
snapping.start()
apps.start()
keyboard.start()
status.start()
