local M = { "nvim-java/nvim-java" }
M.dependencies = {
  'neovim/nvim-lspconfig',
}
M.opts = {
  -- jdtls comes from Nix (nix/modules/dev.nix), not mason
  jdk = { auto_install = false },
}
return {}
