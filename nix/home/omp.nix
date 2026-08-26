{
  pkgs,
  lib,
  config,
  inputs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  ponytail = inputs.ponytail;
  asdSte100 = inputs.asd-ste100;
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

    # OMP loads user extensions directly from this directory. Nix installs all
    # managed entry points, so no mutable plugin registry or live OMP process is
    # required during activation.
    home.file.".omp/agent/extensions/herdr-omp-agent-state.ts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/omp/extensions/herdr-omp-agent-state.ts";

    home.file.".omp/agent/extensions/workstreams-metadata.ts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/herdr/plugins/workstreams/omp/workstreams.ts";

    home.file.".omp/agent/extensions/fork-in.ts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dots/.config/omp/plugins/personal/extensions/fork-in.ts";

    home.file.".omp/agent/extensions/ponytail.js".source = "${ponytail}/pi-extension/index.js";

    # Ponytail's Pi extension registers its slash commands and injects its mode
    # rules. Native skill links expose its complete skill set without enabling
    # the mutable OMP plugin registry.
    home.file.".omp/agent/skills/ponytail".source = "${ponytail}/skills/ponytail";
    home.file.".omp/agent/skills/ponytail-review".source = "${ponytail}/skills/ponytail-review";
    home.file.".omp/agent/skills/ponytail-audit".source = "${ponytail}/skills/ponytail-audit";
    home.file.".omp/agent/skills/ponytail-debt".source = "${ponytail}/skills/ponytail-debt";
    home.file.".omp/agent/skills/ponytail-gain".source = "${ponytail}/skills/ponytail-gain";
    home.file.".omp/agent/skills/ponytail-help".source = "${ponytail}/skills/ponytail-help";
    home.file.".omp/agent/skills/asd-ste100".source = asdSte100;

    # Keep OMP's package registry empty and declarative. Native extensions above
    # replace the old `omp plugin link` state.
    home.file.".omp/plugins/package.json".text = builtins.toJSON {
      name = "omp-plugins";
      private = true;
      dependencies = { };
    };

    home.file.".omp/plugins/omp-plugins.lock.json".text = builtins.toJSON {
      plugins = { };
      settings = { };
    };
  };
in
if standaloneHome then
  userConfig { inherit config; }
else
  { home-manager.users.${username} = userConfig; }
