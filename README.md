# Fr1nge's Dotfiles

Personal system and home configuration managed with a Nix flake. The repository
contains one NixOS host, two standalone Home Manager profiles, one nix-darwin
host, and the application configuration they share.

This is a personal configuration rather than a generic installer. Usernames,
home directories, hardware, storage, and host-specific settings should be
reviewed before activating it on another machine.

## Hosts

| Host | Flake output | Platform | Purpose |
| --- | --- | --- | --- |
| `ursa` | `nixosConfigurations.ursa` | `x86_64-linux` | NixOS desktop with Hyprland and impermanence |
| `ara` | `homeConfigurations.ara` | `x86_64-linux` | Standalone Home Manager desktop profile |
| `lyra` | `homeConfigurations.lyra` | `x86_64-linux` | Standalone Home Manager headless development profile |
| `vela` | `darwinConfigurations.vela` | `aarch64-darwin` | nix-darwin macOS profile |

The main desktop stack is Hyprland, Eww/Waybar, Mako, Alacritty, tmux, zsh,
Neovim, Firefox, and Catppuccin Mocha.

## Repository layout

- `nix/flake.nix` defines the system, Home Manager, Darwin, package, and overlay outputs.
- `nix/hosts/` contains the host entrypoints.
- `nix/modules/` contains NixOS modules.
- `nix/home/` contains shared Home Manager modules.
- `nix/hardware/` contains machine-specific hardware configuration.
- `nix/pkgs/` contains custom packages exposed through the flake and `pkgs.our` overlay.
- `.config/` contains application configuration used by Home Manager.
- `.local/bin/` contains personal scripts installed into the home profile.

Application configuration should remain readable in `.config/`. Home Manager
either installs those files directly or uses them as the source for generated
configuration. In particular, `.config/tmux/tmux.conf` is the single source for
the custom tmux configuration.

On macOS, `.config/hammerspoon/config.lua` treats Tern as a terminal so its Ctrl
keys reach Tern unchanged. Tern keeps its Ctrl-A prefix and per-key Cmd bindings
in `~/Library/Application Support/Tern/settings.json`, outside this repository.
Hammerspoon also routes macOS-owned Cmd shortcuts through Tern's focused-view
bindings so terminal Meta keys do not replace file-editor shortcuts.

Ctrl-A 1 through Ctrl-A 9 select tabs 1 through 9, and Ctrl-A 0 selects tab 10.
These bindings replace the tmux preset's zero-based tab shortcuts.

Ctrl-A W opens Tern's session picker, and Ctrl-A Shift-N creates a plain
session. Ctrl-A P opens Workstreams on the selected host. Use `/` to search
branches, paths, repositories, and references. Use `n` to create a worktree
and open its session. Ctrl-A Shift-W opens the creation form directly. The
plugin keeps a created worktree if session creation fails. Reuse the same
branch to retry the session.

Ctrl-A Shift-Z opens pause confirmation, and Ctrl-A Shift-F shows references
for the focused worktree. In the manager, use `p` to pause, `r` to list paused
sessions, and `f` to browse references. Pause saves tab names and directories,
then closes the session and stops its programs. Restore reopens those tabs
but does not resume programs or rebuild split layouts. The worktree stays on
disk. Pin or dismiss a reference with Space or `x`.

The plugin source is `.config/tern/plugins/workstreams/`. Copy it to each host,
then run `tern plugin link ~/.dots/.config/tern/plugins/workstreams` there.
The host needs Git. The plugin uses `git-ns` snapshots when available and
normal `git worktree add` otherwise. It writes worktrees to
`HERDR_WORKTREES_DIR` or `~/.herdr/worktrees`.

Home Manager links the OMP extension in that plugin to
`~/.omp/agent/extensions/tern-workstreams.ts`. New OMP sessions in Tern
capture Jira IDs, GitHub pull requests, and URLs. The extension writes the
references to the selected host's plugin data; the manager imports them when
it opens or refreshes. Run `bun .config/tern/plugins/workstreams/omp/workstreams.ts`
to check the reference parser.

## Prerequisites

- Nix with the `nix-command` and `flakes` features enabled.
- `home-manager` for the standalone Linux profiles.
- `nix-darwin` for the macOS profile.
- `just` for the repository shortcuts below.
- `nh`, `nixfmt`, and `nom` for the recipes that invoke them.

## Installation and activation

Clone the repository at the path expected by the live configuration links:

```sh
git clone https://github.com/arg3t/dotfiles.git ~/.dots
cd ~/.dots
nix flake check ./nix
```

Activate the appropriate host:

```sh
# NixOS desktop
nh os switch ./nix#ursa

# Standalone Home Manager profiles
home-manager switch --flake ./nix#ara
home-manager switch --flake ./nix#lyra

# macOS
darwin-rebuild switch --flake ./nix#vela
```

`ursa` contains machine-specific LUKS, Btrfs, impermanence, and hardware
configuration. Do not activate it unchanged on different hardware.

Machine-local script settings and secrets can be added to
`~/.config/config.env.local`; the generated `~/.config/config.env` sources it
when present.

## Common commands

Run `just` to list the available recipes.

| Command | Action |
| --- | --- |
| `just check` | Evaluate and check all flake outputs |
| `just test` | Alias for `just check` |
| `just fmt` | Format the Nix files with `nixfmt` |
| `just build` | Build the custom `oh-my-pi` package with `nom` |
| `just update` | Update flake inputs, then check the flake |
| `just switch` | Activate the NixOS configuration with `nh` |
| `just boot` | Build the NixOS configuration for the next boot |
| `just clean` | Remove old Nix generations while retaining five rollbacks |

The `switch` and `boot` recipes are intended for the NixOS host. The standalone
Home Manager and nix-darwin profiles use their explicit activation commands
above.
