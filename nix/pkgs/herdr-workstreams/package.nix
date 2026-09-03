{
  lib,
  buildGoModule,
}:

buildGoModule {
  pname = "herdr-workstreams";
  version = "0.1.0";

  src = ../../../.config/herdr/plugins/workstreams;
  vendorHash = null;

  subPackages = [ "cmd/herdr-workstreams" ];

  postInstall = ''
    pluginRoot=$out/share/herdr-workstreams
    mkdir -p "$pluginRoot/bin"
    ln -s "$out/bin/herdr-workstreams" "$pluginRoot/bin/herdr-workstreams"

    cat > "$pluginRoot/herdr-plugin.toml" <<'EOF'
    id = "workstreams"
    name = "Workstreams"
    version = "0.1.0"
    min_herdr_version = "0.8.0"
    description = "Task-oriented Herdr workstreams with a native palette, worktree lifecycle, and OMP metadata."
    platforms = ["linux", "macos"]

    [[actions]]
    id = "open"
    title = "Open Workstreams"
    contexts = ["workspace", "pane"]
    command = ["./bin/herdr-workstreams", "plugin", "open"]

    [[actions]]
    id = "palette"
    title = "Open Herdr palette"
    contexts = ["workspace", "pane"]
    command = ["./bin/herdr-workstreams", "plugin", "palette"]

    [[actions]]
    id = "create"
    title = "Create workstream"
    contexts = ["workspace", "pane"]
    command = ["./bin/herdr-workstreams", "plugin", "create"]

    [[actions]]
    id = "pause"
    title = "Pause workstream"
    contexts = ["workspace", "pane"]
    command = ["./bin/herdr-workstreams", "plugin", "pause"]

    [[actions]]
    id = "restore"
    title = "Restore workstream"
    contexts = ["workspace", "pane"]
    command = ["./bin/herdr-workstreams", "plugin", "restore"]

    [[actions]]
    id = "refs"
    title = "Browse workstream references"
    contexts = ["workspace", "pane"]
    command = ["./bin/herdr-workstreams", "plugin", "refs"]

    [[panes]]
    id = "overlay"
    title = "Workstreams"
    placement = "overlay"
    command = ["bash", "-c", "exec \"$HERDR_PLUGIN_ROOT/bin/herdr-workstreams\" overlay"]

    [[panes]]
    id = "palette"
    title = "Herdr palette"
    placement = "overlay"
    command = ["bash", "-c", "exec \"$HERDR_PLUGIN_ROOT/bin/herdr-workstreams\" palette"]
    EOF
  '';

  passthru.pluginRoot = "${placeholder "out"}/share/herdr-workstreams";

  meta = {
    description = "Native Herdr workstreams and command palette";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
