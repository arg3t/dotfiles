{ ... }:

{
  programs.zsh.enable = true;

  programs.starship.enable = true;

  environment.shellAliases = {
    cat = "bat";
    ga = "git add";
    gc = "git commit";
    gcm = "git commit -m";
  };
}
