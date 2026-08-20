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
      our.herdr-workstreams
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

    # Herdr reads this registry at startup. Nix owns it so plugin availability
    # does not depend on a live server, a local build, or a post-switch sync.
    xdg.configFile."herdr/plugins.json".text = builtins.toJSON [
      {
        plugin_id = "vim-herdr-navigation";
        name = "Vim Herdr Navigation";
        version = "0.1.0";
        min_herdr_version = "0.7.0";
        description = "Seamless Ctrl+h/j/k/l navigation across herdr panes and Vim/Neovim splits";
        manifest_path = "${config.home.homeDirectory}/.config/herdr/plugins/vim-herdr-navigation/herdr-plugin.toml";
        plugin_root = "${config.home.homeDirectory}/.config/herdr/plugins/vim-herdr-navigation";
        enabled = true;
        platforms = [ "linux" "macos" ];
        actions = map (direction: {
          id = direction;
          title = "Navigate ${direction} (Vim/herdr)";
          contexts = [ "global" ];
          command = [ "bash" "navigate.sh" direction ];
        }) [ "down" "left" "right" "up" ];
        source.kind = "local";
      }
      {
        plugin_id = "workstreams";
        name = "Workstreams";
        version = "0.1.0";
        min_herdr_version = "0.8.0";
        description = "Task-oriented Herdr workstreams with a native palette, worktree lifecycle, and OMP metadata.";
        manifest_path = "${pkgs.our.herdr-workstreams}/share/herdr-workstreams/herdr-plugin.toml";
        plugin_root = "${pkgs.our.herdr-workstreams}/share/herdr-workstreams";
        enabled = true;
        platforms = [ "linux" "macos" ];
        actions = [
          {
            id = "open";
            title = "Open Workstreams";
            contexts = [ "workspace" "pane" ];
            command = [ "./bin/herdr-workstreams" "plugin" "open" ];
          }
          {
            id = "palette";
            title = "Open Herdr palette";
            contexts = [ "workspace" "pane" ];
            command = [ "./bin/herdr-workstreams" "plugin" "palette" ];
          }
          {
            id = "pause";
            title = "Pause focused workstream";
            contexts = [ "workspace" ];
            command = [ "./bin/herdr-workstreams" "pause-focused" ];
          }
        ];
        panes = [
          {
            id = "overlay";
            title = "Workstreams";
            placement = "overlay";
            command = [ "./bin/herdr-workstreams" "overlay" ];
          }
          {
            id = "palette";
            title = "Herdr palette";
            placement = "overlay";
            command = [ "./bin/herdr-workstreams" "palette" ];
          }
        ];
        source.kind = "local";
      }
    ];


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
