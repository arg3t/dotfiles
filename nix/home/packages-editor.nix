{
  lib,
  pkgs,
  config,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = { config, ... }: {
    home.packages = with pkgs; [
      neovim
      our.oh-my-pi
      our.codex
      our.opencode
      our.pi

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
      ripgrep
      fd
    ];

    xdg.configFile."nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim";

    xdg.configFile."zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zed/settings.json";
    xdg.configFile."zed/keymap.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zed/keymap.json";
    xdg.configFile."zed/themes".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/zed/themes";
  };
in
if standaloneHome then
  userConfig { inherit config; }
else
  { home-manager.users.${username} = userConfig; }
