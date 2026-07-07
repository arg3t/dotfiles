{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
  };

  # LSP servers, declaratively (replaces mason.nvim, which downloads generic
  # dynamically-linked binaries that break on NixOS).
  # One entry per M.mason list previously in nvim/lua/lsp/*.lua.
  environment.systemPackages = with pkgs; [
    bash-language-server # bashls
    clang-tools # clangd
    cmake-language-server # cmake
    asm-lsp # asm_lsp
    gopls
    jdt-language-server # jdtls
    vscode-langservers-extracted # html, cssls, eslint, jsonls
    typescript-language-server # ts_ls
    svelte-language-server # svelte
    lua-language-server # lua_ls
    pyright
    ruff
    rust-analyzer
    tinymist # typst
    nil # nix

    # non-LSP tooling nvim configs expect
    tree-sitter
    gcc # nvim-treesitter compiles grammars
    ripgrep
    fd
  ];

  home-manager.users.yeet = {
    home.file.".config/nvim".source = ../../.config/nvim;
  };
}
