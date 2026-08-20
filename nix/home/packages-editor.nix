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
      our.pi
      jq # vim-herdr-navigation: detect vim in focused pane
      go # build local Herdr plugins on each platform

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

    xdg.configFile."herdr/plugins/workstreams".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/herdr/plugins/workstreams";

    # Link active Herdr plugins when a server is available. Herdr owns its
    # plugin registry through the live socket, so an SSH home-switch without a
    # running server cannot register actions; `just herdr-sync` does it later.
    home.activation.linkHerdrPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if HOME="${config.home.homeDirectory}" herdr plugin list >/dev/null 2>&1; then
        run env HOME="${config.home.homeDirectory}" herdr plugin unlink fullerzz.sesh 2>/dev/null || true
        run env HOME="${config.home.homeDirectory}" herdr plugin unlink jt.command-palette 2>/dev/null || true
        run env HOME="${config.home.homeDirectory}" herdr plugin unlink gh-pr 2>/dev/null || true
        run env HOME="${config.home.homeDirectory}" herdr plugin unlink workstream 2>/dev/null || true
        run env HOME="${config.home.homeDirectory}" herdr plugin unlink flow 2>/dev/null || true
        run ${pkgs.go}/bin/go -C "${config.home.homeDirectory}/.config/herdr/plugins/workstreams" build -o bin/herdr-workstreams ./cmd/herdr-workstreams
        run env HOME="${config.home.homeDirectory}" herdr plugin link "${config.home.homeDirectory}/.config/herdr/plugins/vim-herdr-navigation"
        run env HOME="${config.home.homeDirectory}" herdr plugin link "${config.home.homeDirectory}/.config/herdr/plugins/workstreams"
      else
        echo "Herdr is not running; start it, then run 'just herdr-sync' from ~/.dots" >&2
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
