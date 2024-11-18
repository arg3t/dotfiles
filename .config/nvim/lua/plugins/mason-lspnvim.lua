local utils = require('utils')
local lsmod = require("lazy.core.util").lsmod

local M = { "williamboman/mason-lspconfig.nvim" }

local required_pkgs = {}

function masonSetup(mod)
  if mod == "lsp" then
    return
  end

  local config = require(mod)
  required_pkgs = utils.mergeTables(required_pkgs, config.mason)
end

-- Load configs from lsp directory
lsmod("lsp", masonSetup)

M.opts = {
  ensure_installed = required_pkgs
}

M.dependencies = {
  "folke/neodev.nvim",
  "williamboman/mason.nvim",
}

return M
