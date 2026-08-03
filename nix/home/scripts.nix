{ username ? "yeet", standaloneHome ? false, ... }:

let
  userConfig = {
    # recursive = true symlinks each script individually instead of making the
    # whole directory one read-only store symlink, so ~/.local/bin stays a real
    # writable directory that installers (e.g. rtk) can drop new binaries into.
    home.file.".local/bin" = {
      source = ../../.local/bin;
      recursive = true;
    };

    xdg.dataFile."applications/lf.desktop".source = ../../.local/share/applications/lf.desktop;
    xdg.dataFile."applications/neomutt.desktop".source = ../../.local/share/applications/neomutt.desktop;
    xdg.dataFile."applications/nvim.desktop".source = ../../.local/share/applications/nvim.desktop;
    xdg.dataFile."applications/ranger.desktop".source = ../../.local/share/applications/ranger.desktop;
    xdg.dataFile."applications/st.desktop".source = ../../.local/share/applications/st.desktop;
    xdg.dataFile."applications/vim.desktop".source = ../../.local/share/applications/vim.desktop;
    xdg.dataFile."applications/zaread.desktop".source = ../../.local/share/applications/zaread.desktop;
    xdg.dataFile."applications/zathura.desktop".source = ../../.local/share/applications/zathura.desktop;
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
