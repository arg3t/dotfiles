package worktree

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestRepositoryRootUsesNestedDirectory(t *testing.T) {
	repo := t.TempDir()
	if output, err := exec.Command("git", "init", "--quiet", repo).CombinedOutput(); err != nil {
		t.Fatalf("git init: %v: %s", err, output)
	}
	nested := filepath.Join(repo, "a", "b")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatal(err)
	}
	got, err := repositoryRoot(context.Background(), nested)
	if err != nil {
		t.Fatal(err)
	}
	if got != repo {
		t.Fatalf("repositoryRoot(%q) = %q, want %q", nested, got, repo)
	}
}

func TestRepositoryRootRejectsNonRepository(t *testing.T) {
	if _, err := repositoryRoot(context.Background(), t.TempDir()); err == nil {
		t.Fatal("repositoryRoot succeeded outside a Git repository")
	}
}

func TestOverlayCreateCreatesSnapshotAtBaseHead(t *testing.T) {
	temp := t.TempDir()
	baseDir := filepath.Join(temp, "worktrees")
	base := filepath.Join(baseDir, ".base-runtime")
	if err := os.MkdirAll(base, 0o755); err != nil {
		t.Fatal(err)
	}

	bin := filepath.Join(temp, "bin")
	if err := os.Mkdir(bin, 0o755); err != nil {
		t.Fatal(err)
	}
	git := filepath.Join(bin, "git")
	if err := os.WriteFile(git, []byte(`#!/bin/sh
printf '%s\n' "$*" >> "$GIT_CALLS"
if [ "$1 $2" = "rev-parse HEAD" ]; then
  printf '%s\n' "$GIT_HEAD"
elif [ "$1 $2 $3" = "ns worktree create" ]; then
  for arg do target=$arg; done
  mkdir -p "$target"
fi
`), 0o755); err != nil {
		t.Fatal(err)
	}
	calls := filepath.Join(temp, "calls")
	t.Setenv("HERDR_WORKTREES_DIR", baseDir)
	t.Setenv("GIT_CALLS", calls)
	t.Setenv("GIT_HEAD", "0123456789abcdef")
	t.Setenv("PATH", bin+string(os.PathListSeparator)+os.Getenv("PATH"))

	target, err := overlayCreate(context.Background(), temp, "runtime", "feature")
	if err != nil {
		t.Fatal(err)
	}
	wantTarget := filepath.Join(baseDir, "runtime", "feature")
	if target != wantTarget {
		t.Fatalf("target = %q, want %q", target, wantTarget)
	}

	got, err := os.ReadFile(calls)
	if err != nil {
		t.Fatal(err)
	}
	want := strings.Join([]string{
		"rev-parse HEAD",
		"ns worktree snapshot create --base " + base + " --commit 0123456789abcdef",
		"ns worktree create --base " + base + " --snapshot 0123456789abcdef " + wantTarget,
		"checkout -b feature",
	}, "\n") + "\n"
	if string(got) != want {
		t.Fatalf("git calls =\n%s\nwant:\n%s", got, want)
	}
}
