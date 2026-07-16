{
  pkgs,
  config,
  lib,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = { config, ... }: {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    home.packages = with pkgs; [
      our.oh-my-pi

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
      tree-sitter
      gcc
      ripgrep
      fd
    ];

    xdg.configFile."nvim".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim"
    );
  };
in
if standaloneHome then
  userConfig { inherit config; }
else
  { home-manager.users.${username} = userConfig; }
