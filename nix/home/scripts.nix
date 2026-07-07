{ ... }:

{
  home-manager.users.yeet = {
    home.file.".local/bin".source = ../../.local/bin;

    home.file.".local/share/applications".source = ../../.local/share/applications;
  };
}
