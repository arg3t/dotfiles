package herdr

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
)

type Client struct{ Binary string }

func New() Client { return Client{Binary: "herdr"} }

type envelope[T any] struct {
	Result T `json:"result"`
	Error  *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func (c Client) run(ctx context.Context, dst any, args ...string) error {
	out, err := exec.CommandContext(ctx, c.Binary, args...).CombinedOutput()
	var response envelope[json.RawMessage]
	if decodeErr := json.Unmarshal(out, &response); decodeErr != nil {
		return fmt.Errorf("herdr %s: %w; output: %s", strings.Join(args, " "), decodeErr, strings.TrimSpace(string(out)))
	}
	if err != nil || response.Error != nil {
		message := "unknown error"
		if response.Error != nil && response.Error.Message != "" {
			message = response.Error.Message
		} else if err != nil {
			message = err.Error()
		}
		return fmt.Errorf("herdr %s: %s", strings.Join(args, " "), message)
	}
	if dst == nil {
		return nil
	}
	if err := json.Unmarshal(response.Result, dst); err != nil {
		return fmt.Errorf("herdr %s: decode result: %w", strings.Join(args, " "), err)
	}
	return nil
}

func (c Client) Workspaces(ctx context.Context) ([]model.Workspace, error) {
	var result struct {
		Workspaces []model.Workspace `json:"workspaces"`
	}
	if err := c.run(ctx, &result, "workspace", "list"); err != nil {
		return nil, err
	}
	return result.Workspaces, nil
}

func (c Client) Workspace(ctx context.Context, id string) (model.Workspace, error) {
	var result struct {
		Workspace model.Workspace `json:"workspace"`
	}
	if err := c.run(ctx, &result, "workspace", "get", id); err != nil {
		return model.Workspace{}, err
	}
	return result.Workspace, nil
}

func (c Client) Focused(ctx context.Context) (model.Workspace, error) {
	workspaces, err := c.Workspaces(ctx)
	if err != nil {
		return model.Workspace{}, err
	}
	for _, workspace := range workspaces {
		if workspace.Focused {
			return c.Workspace(ctx, workspace.ID)
		}
	}
	return model.Workspace{}, fmt.Errorf("no focused workspace")
}

func (c Client) Panes(ctx context.Context, workspaceID string) ([]model.Pane, error) {
	var result struct {
		Panes []model.Pane `json:"panes"`
	}
	if err := c.run(ctx, &result, "pane", "list", "--workspace", workspaceID); err != nil {
		return nil, err
	}
	return result.Panes, nil
}

func (c Client) Tabs(ctx context.Context, workspaceID string) ([]model.Tab, error) {
	var result struct {
		Tabs []model.Tab `json:"tabs"`
	}
	if err := c.run(ctx, &result, "tab", "list", "--workspace", workspaceID); err != nil {
		return nil, err
	}
	return result.Tabs, nil
}

func (c Client) Focus(ctx context.Context, id string) error {
	return c.run(ctx, nil, "workspace", "focus", id)
}
func (c Client) Close(ctx context.Context, id string) error {
	return c.run(ctx, nil, "workspace", "close", id)
}
func (c Client) Rename(ctx context.Context, id, label string) error {
	return c.run(ctx, nil, "workspace", "rename", id, label)
}

func (c Client) Metadata(ctx context.Context, id, name, value string) error {
	return c.run(ctx, nil, "workspace", "report-metadata", id, "--source", "workstreams", "--token", name+"="+value)
}

func (c Client) CreateTab(ctx context.Context, workspaceID, label string) error {
	return c.run(ctx, nil, "tab", "create", "--workspace", workspaceID, "--label", label)
}

func (c Client) OpenWorktree(ctx context.Context, root, path, label string) (model.Workspace, error) {
	var result struct {
		Workspace model.Workspace `json:"workspace"`
	}
	err := c.run(ctx, &result, "worktree", "open", "--cwd", root, "--path", path, "--label", label, "--focus")
	return result.Workspace, err
}

func (c Client) CreateWorktree(ctx context.Context, root, branch, label string) (model.Workspace, error) {
	var result struct {
		Workspace model.Workspace `json:"workspace"`
	}
	err := c.run(ctx, &result, "worktree", "create", "--cwd", root, "--branch", branch, "--label", label, "--focus")
	return result.Workspace, err
}

func (c Client) OpenPluginPane(ctx context.Context) error {
	return c.run(ctx, nil, "plugin", "pane", "open", "--plugin", "workstreams", "--entrypoint", "overlay", "--placement", "overlay", "--focus")
}
