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
      our.herdr
      our.herdr-plugin-sesh
      our.pi
      jq # vim-herdr-navigation: detect vim in focused pane

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

    xdg.configFile."herdr/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/herdr/config.toml";

    xdg.configFile."herdr/plugins/vim-herdr-navigation".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/herdr/plugins/vim-herdr-navigation";

    xdg.configFile."herdr/plugins/herdr-command-palette".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/herdr/plugins/herdr-command-palette";

    # Link vendored plugins into herdr and the sesh plugin from nix store.
    # Runs after config files are placed. Idempotent: re-linking is safe.
    home.activation.linkHerdrPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if command -v herdr >/dev/null 2>&1; then
        run herdr plugin link \
          "$HOME/.config/herdr/plugins/vim-herdr-navigation" 2>/dev/null || true
        run herdr plugin link \
          "$HOME/.config/herdr/plugins/herdr-command-palette" 2>/dev/null || true
        run herdr plugin link \
          "${pkgs.our.herdr-plugin-sesh}/share/herdr-plugin-sesh" 2>/dev/null || true
      fi
    '';

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
