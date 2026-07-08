{ pkgs, config, lib, username ? "yeet", standaloneHome ? false, ... }:

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

    xdg.configFile."nvim/init.lua".source = lib.mkForce (
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/init.lua"
    );

    xdg.configFile."nvim/after".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/after";
    xdg.configFile."nvim/ftdetect".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/ftdetect";
    xdg.configFile."nvim/ftplugin".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/ftplugin";
    xdg.configFile."nvim/indent".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/indent";
    xdg.configFile."nvim/lazy-lock.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/lazy-lock.json";
    xdg.configFile."nvim/lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/lua";
    xdg.configFile."nvim/syntax".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/syntax";
    xdg.configFile."nvim/templates".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/nvim/templates";
  };
in
if standaloneHome then userConfig { inherit config; } else { home-manager.users.${username} = userConfig; }
