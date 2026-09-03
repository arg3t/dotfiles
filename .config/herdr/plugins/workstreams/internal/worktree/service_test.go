package worktree

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
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
