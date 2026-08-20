package worktree

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/herdr"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/refs"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/store"
)

func Ingest(ctx context.Context, client herdr.Client, data store.Store, cwd, title, text, tabID string) error {
	workspace, err := workspaceForCWD(ctx, client, cwd)
	if err != nil {
		return err
	}
	if workspace.Worktree == nil {
		return fmt.Errorf("workspace %q has no worktree", workspace.Label)
	}
	state, err := data.Load()
	if err != nil {
		return err
	}
	key := store.WorkstreamKey(*workspace.Worktree)
	workspaceRenameAllowed, workspaceLocked := autoRenameAllowed(workspace.Label, state.AutoLabels[key], state.TitleLocked[key])
	state.TitleLocked[key] = workspaceLocked
	if title != "" && workspaceRenameAllowed && title != workspace.Label {
		if err := client.Rename(ctx, workspace.ID, title); err != nil {
			return err
		}
		state.AutoLabels[key] = title
	}
	if tabID != "" {
		tab, tabErr := client.Tab(ctx, tabID)
		if tabErr != nil {
			return tabErr
		}
		tabRenameAllowed, tabLocked := autoRenameAllowed(tab.Label, state.TabAutoLabels[tabID], state.TabTitleLocked[tabID])
		state.TabTitleLocked[tabID] = tabLocked
		if title != "" && tabRenameAllowed && title != tab.Label {
			if err := client.RenameTab(ctx, tabID, title); err != nil {
				return err
			}
			state.TabAutoLabels[tabID] = title
		}
	}
	for _, ref := range refs.Extract(text) {
		state.AddReference(key, ref)
	}
	if err := data.Save(state); err != nil {
		return err
	}
	return client.Metadata(ctx, workspace.ID, "refs", referenceSummary(state.References[key]))
}

func autoRenameAllowed(current, lastAutomatic string, locked bool) (allowed, nowLocked bool) {
	if lastAutomatic != "" && current != lastAutomatic {
		locked = true
	}
	return !locked, locked
}

func workspaceForCWD(ctx context.Context, client herdr.Client, cwd string) (model.Workspace, error) {
	workspaces, err := client.Workspaces(ctx)
	if err != nil {
		return model.Workspace{}, err
	}
	clean := filepath.Clean(cwd)
	var best model.Workspace
	for _, row := range workspaces {
		workspace, err := client.Workspace(ctx, row.ID)
		if err != nil || workspace.Worktree == nil {
			continue
		}
		root := filepath.Clean(workspace.Worktree.CheckoutPath)
		if clean == root || strings.HasPrefix(clean, root+string(filepath.Separator)) {
			if best.Worktree == nil || len(root) > len(best.Worktree.CheckoutPath) {
				best = workspace
			}
		}
	}
	if best.Worktree == nil {
		return model.Workspace{}, fmt.Errorf("no workstream owns %s", cwd)
	}
	return best, nil
}

func referenceSummary(references []model.Reference) string {
	parts := make([]string, 0, len(references))
	for _, ref := range references {
		if !ref.Dismissed {
			parts = append(parts, ref.ID)
		}
	}
	return strings.Join(parts, " ")
}
