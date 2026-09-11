package herdr

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestPluginCWD(t *testing.T) {
	for _, test := range []struct {
		name     string
		context  string
		fallback string
		want     string
	}{
		{"focused pane", `{"focused_pane_cwd":"/repo/pane","workspace_cwd":"/repo"}`, "/fallback", "/repo/pane"},
		{"workspace", `{"workspace_cwd":"/repo"}`, "/fallback", "/repo"},
		{"invalid context", `{`, "/fallback", "/fallback"},
		{"empty context", ``, "/fallback", "/fallback"},
	} {
		t.Run(test.name, func(t *testing.T) {
			if got := pluginCWD(test.context, test.fallback); got != test.want {
				t.Fatalf("pluginCWD(%q, %q) = %q, want %q", test.context, test.fallback, got, test.want)
			}
		})
	}
}

func TestPluginPaneCommandsUseExpectedCWD(t *testing.T) {
	dir := t.TempDir()
	if output, err := exec.Command("git", "init", "--quiet", dir).CombinedOutput(); err != nil {
		t.Fatalf("git init: %v: %s", err, output)
	}
	argsFile := filepath.Join(dir, "args")
	binary := filepath.Join(dir, "herdr")
	if err := os.WriteFile(binary, []byte("#!/bin/sh\ncase \"$1:$2\" in\nworkspace:list) printf '%s\\n' '{\"result\":{\"workspaces\":[{\"workspace_id\":\"w1\",\"focused\":true}]}}' ;;\nworkspace:get) printf '{\"result\":{\"workspace\":{\"workspace_id\":\"w1\",\"worktree\":{\"checkout_path\":\"%s\"}}}}\\n' \"$WORKTREE_CWD\" ;;\n*) printf '%s\\n' \"$@\" > \"$ARGS_FILE\" ;;\nesac\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("ARGS_FILE", argsFile)
	t.Setenv("HERDR_PLUGIN_CONTEXT_JSON", "")
	t.Setenv("HERDR_WORKSPACE_CWD", "")
	t.Setenv("WORKTREE_CWD", dir)

	if err := (Client{Binary: binary}).OpenPluginPaneMode(context.Background(), "create"); err != nil {
		t.Fatal(err)
	}
	contents, err := os.ReadFile(argsFile)
	if err != nil {
		t.Fatal(err)
	}
	got := strings.Split(strings.TrimSpace(string(contents)), "\n")
	want := []string{"plugin", "pane", "open", "--plugin", "workstreams", "--entrypoint", "overlay", "--placement", "overlay", "--focus", "--env", "WORKSTREAMS_MODE=create", "--cwd", dir}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("plugin pane arguments = %#v, want %#v", got, want)
	}

	if err := (Client{Binary: binary}).OpenPluginPalette(context.Background()); err != nil {
		t.Fatal(err)
	}
	contents, err = os.ReadFile(argsFile)
	if err != nil {
		t.Fatal(err)
	}
	got = strings.Split(strings.TrimSpace(string(contents)), "\n")
	want = []string{"plugin", "pane", "open", "--plugin", "workstreams", "--entrypoint", "palette", "--placement", "overlay", "--focus"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("palette arguments = %#v, want %#v", got, want)
	}
}

func TestOpenPluginPaneModeUsesGitBackedPane(t *testing.T) {
	dir := t.TempDir()
	if output, err := exec.Command("git", "init", "--quiet", dir).CombinedOutput(); err != nil {
		t.Fatalf("git init: %v: %s", err, output)
	}
	argsFile := filepath.Join(dir, "args")
	binary := filepath.Join(dir, "herdr")
	script := "#!/bin/sh\ncase \"$1:$2\" in\nworkspace:list) printf '%s\\n' '{\"result\":{\"workspaces\":[{\"workspace_id\":\"w1\",\"focused\":true}]}}' ;;\nworkspace:get) printf '%s\\n' '{\"result\":{\"workspace\":{\"workspace_id\":\"w1\"}}}' ;;\npane:list) printf '{\"result\":{\"panes\":[{\"pane_id\":\"p0\",\"cwd\":\"/tmp\",\"foreground_cwd\":\"/tmp\",\"focused\":true},{\"pane_id\":\"p1\",\"cwd\":\"%s\",\"foreground_cwd\":\"%s\",\"focused\":false}]}}\\n' \"$WORKTREE_CWD\" \"$WORKTREE_CWD\" ;;\n*) printf '%s\\n' \"$@\" > \"$ARGS_FILE\" ;;\nesac\n"
	if err := os.WriteFile(binary, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	t.Setenv("ARGS_FILE", argsFile)
	t.Setenv("WORKTREE_CWD", dir)
	t.Setenv("HERDR_PLUGIN_CONTEXT_JSON", `{"focused_pane_cwd":"/tmp"}`)

	if err := (Client{Binary: binary}).OpenPluginPaneMode(context.Background(), "create"); err != nil {
		t.Fatal(err)
	}
	contents, err := os.ReadFile(argsFile)
	if err != nil {
		t.Fatal(err)
	}
	got := strings.Split(strings.TrimSpace(string(contents)), "\n")
	want := []string{"plugin", "pane", "open", "--plugin", "workstreams", "--entrypoint", "overlay", "--placement", "overlay", "--focus", "--env", "WORKSTREAMS_MODE=create", "--cwd", dir}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("plugin pane arguments = %#v, want %#v", got, want)
	}
}
