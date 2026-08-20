package worktree

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/herdr"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/store"
)

type Service struct {
	Herdr herdr.Client
	Store store.Store
}

type Created struct {
	Workspace model.Workspace
	Mode      string
}

func (s Service) Create(ctx context.Context, source model.Workspace, branch string) (Created, error) {
	if source.Worktree == nil || source.Worktree.RepoRoot == "" {
		return Created{}, fmt.Errorf("workspace %q has no worktree", source.Label)
	}
	branch = slug(branch)
	if branch == "" {
		return Created{}, fmt.Errorf("branch name is empty")
	}
	root, wt := source.Worktree.RepoRoot, *source.Worktree
	if overlayAvailable(ctx, root) {
		path, err := overlayCreate(ctx, root, wt.RepoName, branch)
		if err == nil {
			workspace, openErr := s.Herdr.AdoptWorktree(ctx, root, path, branch)
			if openErr == nil {
				return Created{Workspace: workspace, Mode: "overlay"}, nil
			}
			return Created{}, openErr
		}
	}
	workspace, err := s.Herdr.CreateWorktree(ctx, root, branch, branch)
	if err != nil {
		return Created{}, err
	}
	return Created{Workspace: workspace, Mode: "git"}, nil
}

func (s Service) Pause(ctx context.Context, workspace model.Workspace) error {
	if workspace.Worktree == nil {
		return fmt.Errorf("workspace %q has no worktree", workspace.Label)
	}
	tabs, err := s.Herdr.Tabs(ctx, workspace.ID)
	if err != nil {
		return err
	}
	state, err := s.Store.Load()
	if err != nil {
		return err
	}
	key := store.WorkstreamKey(*workspace.Worktree)
	pausedKey := store.PauseKey(*workspace.Worktree)
	labels := make([]string, 0, len(tabs))
	for _, tab := range tabs {
		labels = append(labels, tab.Label)
	}
	state.Paused[pausedKey] = model.Paused{Version: store.Version, Key: pausedKey, Label: workspace.Label, Worktree: *workspace.Worktree, Tabs: labels, Tokens: workspace.Tokens, References: state.References[key], TitleLocked: state.TitleLocked[key], PausedAt: time.Now().UTC()}
	if err := s.Store.Save(state); err != nil {
		return err
	}
	return s.Herdr.Close(ctx, workspace.ID)
}

func (s Service) Restore(ctx context.Context, key string) (model.Workspace, error) {
	state, err := s.Store.Load()
	if err != nil {
		return model.Workspace{}, err
	}
	record, ok := state.Paused[key]
	if !ok {
		return model.Workspace{}, fmt.Errorf("paused workstream %q not found", key)
	}
	if _, err := os.Stat(record.Worktree.CheckoutPath); err != nil {
		return model.Workspace{}, fmt.Errorf("worktree %s is unavailable", record.Worktree.CheckoutPath)
	}
	workspace, err := s.Herdr.OpenWorktree(ctx, record.Worktree.RepoRoot, record.Worktree.CheckoutPath, record.Label)
	if err != nil {
		return model.Workspace{}, err
	}
	for _, label := range record.Tabs[1:] {
		if err := s.Herdr.CreateTab(ctx, workspace.ID, label); err != nil {
			return model.Workspace{}, err
		}
	}
	for name, value := range record.Tokens {
		if err := s.Herdr.Metadata(ctx, workspace.ID, name, value); err != nil {
			return model.Workspace{}, err
		}
	}
	workstreamKey := store.WorkstreamKey(record.Worktree)
	state.References[workstreamKey] = record.References
	state.TitleLocked[workstreamKey] = record.TitleLocked
	delete(state.Paused, key)
	if err := s.Store.Save(state); err != nil {
		return model.Workspace{}, err
	}
	return workspace, nil
}

func overlayAvailable(ctx context.Context, cwd string) bool {
	return exec.CommandContext(ctx, "git", "ns", "worktree", "check").Run() == nil && cwd != ""
}
func overlayCreate(ctx context.Context, root, repo, branch string) (string, error) {
	baseDir := os.Getenv("HERDR_WORKTREES_DIR")
	if baseDir == "" {
		home, _ := os.UserHomeDir()
		baseDir = filepath.Join(home, ".herdr", "worktrees")
	}
	base, target := filepath.Join(baseDir, ".base-"+repo), filepath.Join(baseDir, repo, branch)
	if _, err := os.Stat(base); os.IsNotExist(err) {
		if output, err := command(ctx, root, "git", "ns", "worktree", "setup", base); err != nil {
			return "", fmt.Errorf("git-ns setup: %s", output)
		}
	}
	if output, err := command(ctx, root, "git", "ns", "worktree", "create", "--base", base, target); err != nil {
		return "", fmt.Errorf("git-ns create: %s", output)
	}
	if _, err := command(ctx, target, "git", "checkout", "-b", branch); err != nil {
		if output, attachErr := command(ctx, target, "git", "checkout", branch); attachErr != nil {
			return "", fmt.Errorf("git checkout %s: %s", branch, output)
		}
	}
	return target, nil
}
func command(ctx context.Context, dir, name string, args ...string) (string, error) {
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Dir = dir
	output, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(output)), err
}
func slug(value string) string {
	value = strings.ToLower(strings.TrimSpace(value))
	value = strings.Map(func(r rune) rune {
		if r >= 'a' && r <= 'z' || r >= '0' && r <= '9' || r == '-' || r == '_' || r == '/' {
			return r
		}
		return '-'
	}, value)
	return strings.Trim(value, "-")
}
