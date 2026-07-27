{ config, lib, ... }:

let
  cfg = config.my.login;
in
{
  options.my.login = {
    autoLogin = lib.mkEnableOption "automatic graphical login";

    user = lib.mkOption {
      type = lib.types.str;
      default = "yeet";
      description = "User to log in automatically.";
    };

    session = lib.mkOption {
      type = lib.types.str;
      default = "hyprland";
      description = "Display-manager session name.";
    };
  };

  config = {
    services.displayManager.defaultSession = cfg.session;
    services.displayManager.autoLogin = lib.mkIf cfg.autoLogin {
      enable = true;
      user = cfg.user;
    };
  };
}
