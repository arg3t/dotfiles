local M = { "williamboman/mason-lspconfig.nvim" }
M.opts = {
ensure_installed = require("config.lsp").mason_servers
}

M.dependencies = {
"folke/neodev.nvim"
}

return M


