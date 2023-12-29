return function ()
  require("copilot").setup({
    auto_refresh = false,
    suggestion = {
      enabled = false,
      auto_trigger = false,
    },
    panel = {
      enabled = false
    },
  })
end
