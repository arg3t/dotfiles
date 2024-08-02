local M = { "zbirenbaum/copilot.lua" }
M.cmd = "Copilot"
M.event = "InsertEnter"
M.config = function()
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

return M
