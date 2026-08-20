package store

import (
	"testing"
	"time"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
)

func TestAddReferenceKeepsDismissedTombstone(t *testing.T) {
	state := State{References: map[string][]model.Reference{}, Paused: map[string]model.Paused{}, AutoLabels: map[string]string{}, TitleLocked: map[string]bool{}}
	ref := model.Reference{Kind: model.ReferenceJira, ID: "ES-1234", Discovered: time.Now()}
	if !state.AddReference("workstream", ref) {
		t.Fatal("first reference must be added")
	}
	if !state.SetReference("workstream", ref.Key(), false, true) {
		t.Fatal("reference must be found")
	}
	if state.AddReference("workstream", ref) {
		t.Fatal("dismissed reference must not be restored")
	}
	if got := state.References["workstream"][0]; !got.Dismissed {
		t.Fatal("dismissed tombstone was lost")
	}
}

func TestWorkstreamKeyUsesWorktreePath(t *testing.T) {
	one := WorkstreamKey(model.Worktree{RepoRoot: "/repo", CheckoutPath: "/worktrees/repo/one"})
	two := WorkstreamKey(model.Worktree{RepoRoot: "/repo", CheckoutPath: "/worktrees/repo/two"})
	if one == two {
		t.Fatal("separate checkout paths must have distinct workstream keys")
	}
}

func TestNewUsesStateFileBelowHerdrDirectory(t *testing.T) {
	if got, want := New("/tmp/herdr-state").Path, "/tmp/herdr-state/state.json"; got != want {
		t.Fatalf("New().Path = %q, want %q", got, want)
	}
}
