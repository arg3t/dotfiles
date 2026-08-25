{
  lib,
  pkgs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  rustup-without-rust-analyzer = pkgs.symlinkJoin {
    name = "rustup-${pkgs.rustup.version}";
    paths = [ pkgs.rustup ];
    postBuild = ''
      rm -f $out/bin/rust-analyzer
    '';
  };

  clang-driver-only = pkgs.symlinkJoin {
    name = "clang-driver-${pkgs.llvmPackages.clang-unwrapped.version}";
    paths = [ pkgs.llvmPackages.clang-unwrapped ];
    postBuild = ''
      find $out/bin -maxdepth 1 -type l ! -name 'clang' ! -name 'clang++' ! -name 'clang-[0-9]*' -delete
    '';
  };

  bazelisk-with-bazel = pkgs.symlinkJoin {
    name = "bazelisk-${pkgs.bazelisk.version}";
    paths = [ pkgs.bazelisk ];
    postBuild = ''
      ln -s bazelisk $out/bin/bazel
    '';
  };

  userConfig = {
    home.packages = with pkgs; [
      awscli2
      azure-cli
      github-cli
      kubectl
      docker-client
      terragrunt
      opentofu
      attic-client
      lazygit
      delta
      watchman
      go
      rustup-without-rust-analyzer
      clang-driver-only
      nodejs
      bun
      pnpm
      uv
      gcc
      cmake
      ninja
      gnumake
      pkg-config
      lldb
      gdb
      mold
      bazelisk-with-bazel
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
