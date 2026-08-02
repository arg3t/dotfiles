{
  lib,
  pkgs,
  username ? "yeet",
  standaloneHome ? false,
  ...
}:

let
  # rustup ships a `rust-analyzer` proxy that collides with the standalone
  # rust-analyzer from packages-editor.nix. Use symlinkJoin to drop just that
  # one binary from the prebuilt rustup package, so we keep the binary-cache
  # hit (overrideAttrs would force a ~30min from-source rebuild + test suite).
  rustup-without-rust-analyzer = pkgs.symlinkJoin {
    name = "rustup-${pkgs.rustup.version}";
    paths = [ pkgs.rustup ];
    postBuild = ''
      rm -f $out/bin/rust-analyzer
    '';
  };

  # .cargo/config.toml uses clang as the linker for Rust builds. The full
  # llvmPackages.clang-unwrapped shares many binaries with the clang-tools
  # package from packages-editor.nix (clang-apply-replacements, clang-doc, …),
  # which buildEnv rejects as a conflict. Expose only the clang/clang++ driver
  # binaries that the linker invocation actually needs.
  clang-driver-only = pkgs.symlinkJoin {
    name = "clang-driver-${pkgs.llvmPackages.clang-unwrapped.version}";
    paths = [ pkgs.llvmPackages.clang-unwrapped ];
    postBuild = ''
      find $out/bin -maxdepth 1 -type l ! -name 'clang' ! -name 'clang++' ! -name 'clang-[0-9]*' -delete
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
      # gopls (packages-editor.nix) is useless without the toolchain itself,
      # and GOPATH/$GOPATH/bin are already wired up in env.nix.
      go
      rustup-without-rust-analyzer
      clang-driver-only
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      mold
    ];
  };
in
if standaloneHome then userConfig else { home-manager.users.${username} = userConfig; }
