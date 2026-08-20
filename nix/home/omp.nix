{
  pkgs,
  lib,
  config,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  userConfig = { config, ... }: {
    # OMP user-level config files. These are discovery-only files that OMP
    # never writes to, so out-of-store symlinks are safe: edits in the dotfiles
    # repo are reflected on the next OMP session without a home-switch.
    #
    # Runtime state (config.yml, agent.db, sessions/, models.db, mcp.json,
    # ssh.json) is intentionally not managed — OMP owns those at runtime.
    home.file.".omp/agent/APPEND_SYSTEM.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/omp/agent/APPEND_SYSTEM.md";

    home.file.".omp/agent/RULES.md".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/omp/agent/RULES.md";

    home.file.".omp/agent/rules".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/omp/agent/rules";

    # Herdr's stock integration owns agent-state reporting. This companion
    # observes OMP titles and references, then delegates persistence to Go.
    home.file.".omp/agent/extensions/workstreams-metadata.ts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/herdr/plugins/workstreams/omp/workstreams.ts";


    # Link the dotfiles-owned OMP plugin. Its extensions include fork-in.
    home.activation.linkOmpPlugins = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      if command -v omp >/dev/null 2>&1; then
        run omp plugin link \
          "$HOME/.dots/.config/omp/plugins/personal" 2>/dev/null || true
        run omp plugin uninstall fork-in 2>/dev/null || true
      fi
    '';
  };
in
if standaloneHome then
  userConfig { inherit config; }
else
  { home-manager.users.${username} = userConfig; }
