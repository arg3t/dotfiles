#!/usr/bin/env bash
# setup-nix.sh — generate the NixOS config we discussed.
# Run from your nix config folder (either ~/dotfiles itself or a folder
# directly inside it, e.g. ~/dotfiles/nix). Dotfiles expected at ~/dotfiles.
#
# Writes: flake.nix, hosts/ursa.nix, modules/*, home/*
# Never touches: hardware/ursa.nix, your .config/*, .local/*
set -euo pipefail

DOTFILES="$HOME/dotfiles"
[ -d "$DOTFILES/.config" ] || { echo "ERROR: $DOTFILES/.config not found"; exit 1; }

# Figure out where the dotfiles root is relative to a nix file one level deep
# (e.g. home/env.nix). Two supported layouts:
#   nix root == ~/dotfiles          -> ../
#   nix root == ~/dotfiles/<sub>    -> ../../
if [ "$PWD" -ef "$DOTFILES" ]; then
  DOTS=".."
elif [ "$(cd .. && pwd)" -ef "$DOTFILES" ]; then
  DOTS="../.."
else
  echo "ERROR: run this from ~/dotfiles or a directory directly inside it"; exit 1
fi

if [ ! -f hardware/ursa.nix ]; then
  echo "WARNING: hardware/ursa.nix missing. Copy your generated hardware config there."
fi

mkdir -p hosts hardware modules home

# ---------------------------------------------------------------- flake.nix
cat > flake.nix <<'EOF'
{
  description = "Alpha Centauri flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, home-manager, impermanence, ... }@inputs:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.ursa = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };

        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          ./hosts/ursa.nix
        ];
      };
    };
}
EOF

# ------------------------------------------------------------ hosts/ursa.nix
cat > hosts/ursa.nix <<'EOF'
{ pkgs, ... }:

{
  imports = [
    ../hardware/ursa.nix

    ../modules/nix.nix
    ../modules/base.nix
    ../modules/users.nix
    ../modules/impermanence.nix
    ../modules/bluetooth.nix
    ../modules/audio.nix

    ../modules/hyprland.nix
    ../modules/waybar.nix
    ../modules/packages.nix
    ../modules/login.nix
    ../modules/shell.nix
    ../modules/dev.nix

    ../home/base.nix
    ../home/env.nix
    ../home/scripts.nix
    ../home/shell.nix
    ../home/terminal.nix
    ../home/git.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "ursa";

  my.login = {
    autoLogin = true;
    user = "yeet";
    session = "hyprland";
  };

  system.stateVersion = "26.05";
}
EOF

# ------------------------------------------------------------ modules/nix.nix
cat > modules/nix.nix <<'EOF'
{ ... }:

{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  nix.settings.trusted-users = [
    "root"
    "yeet"
    "@wheel"
  ];

  nix.settings.sandbox = true;
  nix.settings.builders-use-substitutes = true;
  nix.settings.auto-optimise-store = true;
}
EOF

# ----------------------------------------------------------- modules/base.nix
cat > modules/base.nix <<'EOF'
{ lib, ... }:

{
  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  networking.networkmanager.enable = true;
  networking.useDHCP = lib.mkDefault true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  security.sudo.wheelNeedsPassword = true;

  programs.nix-index.enable = true;
}
EOF

# ---------------------------------------------------------- modules/users.nix
cat > modules/users.nix <<'EOF'
{ pkgs, ... }:

{
  # Impermanence: /etc/shadow lives on the wiped root subvolume, so passwords
  # must be declarative. Create the hash BEFORE rebooting:
  #   sudo mkdir -p /persist/passwords
  #   mkpasswd -m sha-512 | sudo tee /persist/passwords/yeet
  #   sudo chmod 600 /persist/passwords/yeet
  users.mutableUsers = false;

  users.users.yeet = {
    isNormalUser = true;
    description = "YEAT";
    hashedPasswordFile = "/persist/passwords/yeet";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];

    shell = pkgs.zsh;
  };
}
EOF

# -------------------------------------------------- modules/impermanence.nix
cat > modules/impermanence.nix <<'EOF'
{ lib, ... }:

{
  # /persist must be mounted before the impermanence bind mounts are set up.
  fileSystems."/persist".neededForBoot = true;

  # Roll the root subvolume back to the blank snapshot on every boot.
  # Runs in initrd (systemd stage 1), after LUKS is opened, before /sysroot
  # is mounted.
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.services.rollback = {
    description = "Rollback btrfs root subvolume to blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@krypt.service" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/mapper/krypt /mnt

      # Delete nested subvolumes under root first (srv, tmp, var/tmp,
      # var/lib/portables, var/lib/machines, ...), then root itself.
      btrfs subvolume list -o /mnt/root |
        cut -f9- -d' ' |
        while read -r subvolume; do
          btrfs subvolume delete "/mnt/$subvolume"
        done

      btrfs subvolume delete /mnt/root
      btrfs subvolume snapshot /mnt/root-blank /mnt/root

      umount /mnt
    '';
  };

  # State that must survive the wipe. /home, /nix, /var/log and /persist are
  # their own subvolumes and are never touched.
  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/bluetooth"
      "/etc/NetworkManager/system-connections"
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
  };
}
EOF

# ---------------------------------------------------------- modules/audio.nix
cat > modules/audio.nix <<'EOF'
{ ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
}
EOF

# ------------------------------------------------------ modules/bluetooth.nix
cat > modules/bluetooth.nix <<'EOF'
{ ... }:

{
  hardware.bluetooth.enable = true;

  services.blueman.enable = true;
}
EOF

# ---------------------------------------------------------- modules/login.nix
cat > modules/login.nix <<'EOF'
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
EOF

# ------------------------------------------------------- modules/hyprland.nix
cat > modules/hyprland.nix <<'EOF'
{ pkgs, ... }:

{
  programs.hyprland.enable = true;

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = with pkgs; [
    xdg-desktop-portal-gtk
  ];

  environment.systemPackages = with pkgs; [
    kitty
    alacritty
    firefox
    bemenu
    mako
    grim
    slurp
    wl-clipboard
    hyprpaper
    hyprlock
    hypridle
  ];

  home-manager.users.yeet = {
    home.file.".config/hypr".source = @DOTS@/.config/hypr;
    home.file.".config/mako".source = @DOTS@/.config/mako;
    home.file.".config/wofi".source = @DOTS@/.config/wofi;
    home.file.".config/bemenu".source = @DOTS@/.config/bemenu;
  };
}
EOF

# --------------------------------------------------------- modules/waybar.nix
cat > modules/waybar.nix <<'EOF'
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    waybar

    # Deps of the waybar config and status-bar scripts
    jq
    curl
    pavucontrol
    networkmanagerapplet
  ];

  home-manager.users.yeet = {
    home.file.".config/waybar".source = @DOTS@/.config/waybar;
  };
}
EOF

# ------------------------------------------------------- modules/packages.nix
cat > modules/packages.nix <<'EOF'
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    awscli2
    azure-cli
    github-cli

    git
    git-lfs
    curl
    wget
    ripgrep
    fd
    jq
    htop
    fzf
    eza
    tree
    unzip
    zip
    bat
    file
    tmux
    fastfetch
    magic-wormhole

    nix-forecast
    nix-health
    nix-info
    nix-update
    nixfmt
    nixpkgs-reviewFull
    nixpkgs-track
  ];
}
EOF

# ---------------------------------------------------------- modules/shell.nix
cat > modules/shell.nix <<'EOF'
{ ... }:

{
  programs.zsh.enable = true;

  environment.shellAliases = {
    cat = "bat";
    ga = "git add";
    gc = "git commit";
    gcm = "git commit -m";
  };
}
EOF

# ------------------------------------------------------------ modules/dev.nix
cat > modules/dev.nix <<'EOF'
{ ... }:

{
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    defaultEditor = true;
  };

  home-manager.users.yeet = {
    home.file.".config/nvim".source = @DOTS@/.config/nvim;
  };
}
EOF

# --------------------------------------------------------------- home/base.nix
cat > home/base.nix <<'EOF'
{ ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.yeet = {
    home.username = "yeet";
    home.homeDirectory = "/home/yeet";
    home.stateVersion = "26.05";

    programs.home-manager.enable = true;
  };
}
EOF

# ---------------------------------------------------------------- home/env.nix
cat > home/env.nix <<'EOF'
{ ... }:

{
  home-manager.users.yeet = {
    # Manages XDG base dirs declaratively (XDG_CONFIG_HOME, XDG_DATA_HOME,
    # XDG_CACHE_HOME) instead of exporting them in .profile.
    xdg.enable = true;

    home.sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "alacritty";
      OPENER = "xdg-open";

      BAT_THEME = "Catppuccin Mocha";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      # Keep tool homes out of ~. Note: no session variable may reference
      # another session variable, so these are spelled out.
      CARGO_HOME = "$HOME/.local/share/cargo";
      GOPATH = "$HOME/.local/share/go";
      GNUPGHOME = "$HOME/.local/share/gnupg";

      MPV_IPC = "$XDG_RUNTIME_DIR/mpv.socket";
    };

    home.sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.local/share/cargo/bin"
      "$HOME/.local/share/go/bin"
    ];

    # Script-facing config; status-bar scripts `source ~/.config/config.env`.
    # Machine-local secrets go in ~/.config/config.env.local (untracked).
    home.file.".config/config.env".text = ''
      LOCATION=Delft
      BUIENRADAR=1

      if [ -f "$HOME/.config/config.env.local" ]; then
        . "$HOME/.config/config.env.local"
      fi
    '';
  };
}
EOF

# ------------------------------------------------------------ home/scripts.nix
cat > home/scripts.nix <<'EOF'
{ ... }:

{
  home-manager.users.yeet = {
    home.file.".local/bin".source = @DOTS@/.local/bin;

    home.file.".local/share/applications".source = @DOTS@/.local/share/applications;
  };
}
EOF

# -------------------------------------------------------------- home/shell.nix
cat > home/shell.nix <<'EOF'
{ ... }:

{
  home-manager.users.yeet = {
    # Your zsh config (antidote, p10k, aliases, cmds) stays as real files.
    # programs.zsh is intentionally NOT enabled here: it would generate its
    # own .zshrc and fight the linked directory.
    home.file.".config/zsh".source = @DOTS@/.config/zsh;

    # Declarative .zshenv replacing `source ~/.profile`:
    #  - loads Home Manager session variables (hm-session-vars.sh)
    #  - points zsh at ~/.config/zsh
    home.file.".zshenv".text = ''
      for f in \
        "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" \
        "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; do
        [ -f "$f" ] && . "$f" && break
      done

      export ZDOTDIR="$HOME/.config/zsh"
    '';

    # Replaces the imperative `eval $(ssh-agent)` from the old .profile.
    services.ssh-agent.enable = true;

    programs.starship.enable = false;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
EOF

# ----------------------------------------------------------- home/terminal.nix
cat > home/terminal.nix <<'EOF'
{ ... }:

{
  home-manager.users.yeet = {
    home.file.".config/alacritty".source = @DOTS@/.config/alacritty;
    home.file.".config/tmux".source = @DOTS@/.config/tmux;
    home.file.".config/starship.toml".source = @DOTS@/.config/starship.toml;
  };
}
EOF

# ---------------------------------------------------------------- home/git.nix
cat > home/git.nix <<'EOF'
{ ... }:

{
  home-manager.users.yeet = {
    home.file.".gitconfig".source = @DOTS@/.gitconfig;
  };
}
EOF

# Fix up relative dotfile paths for this layout.
for f in modules/hyprland.nix modules/waybar.nix modules/dev.nix \
         home/scripts.nix home/shell.nix home/terminal.nix home/git.nix; do
  sed "s|@DOTS@|$DOTS|g" "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done

echo
echo "Files written. Before you switch:"
echo
echo "  1. Password (REQUIRED, or you are locked out after reboot):"
echo "       sudo mkdir -p /persist/passwords"
echo "       mkpasswd -m sha-512 | sudo tee /persist/passwords/yeet"
echo "       sudo chmod 600 /persist/passwords/yeet"
echo
echo "  2. Build first:"
echo "       sudo nixos-rebuild build --flake .#ursa"
echo
echo "  3. Then switch and reboot:"
echo "       sudo nixos-rebuild switch --flake .#ursa"
echo
echo "  4. First reboot wipes / back to root-blank. /home, /nix, /var/log,"
echo "     /persist survive. Anything else you care about under / must be"
echo "     added to environment.persistence in modules/impermanence.nix."
