package herdr

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
)

type PluginAction struct {
	ID       string `json:"action_id"`
	PluginID string `json:"plugin_id"`
	Title    string `json:"title"`
}

type Client struct{ Binary string }

func New() Client { return Client{Binary: "herdr"} }

type envelope[T any] struct {
	Result T `json:"result"`
	Error  *struct {
		Message string `json:"message"`
	} `json:"error"`
}

func pluginCWD(contextJSON, fallback string) string {
	var context struct {
		FocusedPaneCWD string `json:"focused_pane_cwd"`
		WorkspaceCWD   string `json:"workspace_cwd"`
	}
	if json.Unmarshal([]byte(contextJSON), &context) == nil {
		if context.FocusedPaneCWD != "" {
			return context.FocusedPaneCWD
		}
		if context.WorkspaceCWD != "" {
			return context.WorkspaceCWD
		}
	}
	return fallback
}

func appendCWD(args []string, cwd string) []string {
	if info, err := os.Stat(cwd); err == nil && info.IsDir() {
		return append(args, "--cwd", cwd)
	}
	return args
}

func appendPluginCWD(args []string) []string {
	return appendCWD(args, pluginCWD(os.Getenv("HERDR_PLUGIN_CONTEXT_JSON"), os.Getenv("HERDR_WORKSPACE_CWD")))
}

func (c Client) run(ctx context.Context, dst any, args ...string) error {
	out, err := exec.CommandContext(ctx, c.Binary, args...).CombinedOutput()
	if err == nil && len(strings.TrimSpace(string(out))) == 0 {
		return nil
	}
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

func (c Client) Tab(ctx context.Context, id string) (model.Tab, error) {
	var result struct {
		Tab model.Tab `json:"tab"`
	}
	if err := c.run(ctx, &result, "tab", "get", id); err != nil {
		return model.Tab{}, err
	}
	return result.Tab, nil
}

func (c Client) RenameTab(ctx context.Context, id, label string) error {
	return c.run(ctx, nil, "tab", "rename", id, label)
}

func (c Client) Focus(ctx context.Context, id string) error {
	return c.run(ctx, nil, "workspace", "focus", id)
}

func (c Client) FocusTab(ctx context.Context, id string) error {
	return c.run(ctx, nil, "tab", "focus", id)
}

func (c Client) PluginActions(ctx context.Context) ([]PluginAction, error) {
	var result struct {
		Actions []PluginAction `json:"actions"`
	}
	if err := c.run(ctx, &result, "plugin", "action", "list"); err != nil {
		return nil, err
	}
	return result.Actions, nil
}

func (c Client) InvokePluginAction(ctx context.Context, action PluginAction) error {
	return c.run(ctx, nil, "plugin", "action", "invoke", action.ID, "--plugin", action.PluginID)
}

func (c Client) CreateWorkspace(ctx context.Context, cwd string) error {
	return c.run(ctx, nil, "workspace", "create", "--cwd", cwd, "--focus")
}

func (c Client) CreateTabAt(ctx context.Context, workspaceID, cwd string) error {
	return c.run(ctx, nil, "tab", "create", "--workspace", workspaceID, "--cwd", cwd, "--focus")
}

func (c Client) SplitCurrent(ctx context.Context, direction, cwd string) error {
	return c.run(ctx, nil, "pane", "split", "--current", "--direction", direction, "--cwd", cwd, "--focus")
}

func (c Client) ToggleCurrentZoom(ctx context.Context) error {
	return c.run(ctx, nil, "pane", "zoom", "--current", "--toggle")
}
func (c Client) Close(ctx context.Context, id string) error {
	return c.run(ctx, nil, "workspace", "close", id)
}
func (c Client) Rename(ctx context.Context, id, label string) error {
	return c.run(ctx, nil, "workspace", "rename", id, label)
}

func (c Client) Metadata(ctx context.Context, id, name, value string) error {
	if value == "" {
		return c.run(ctx, nil, "workspace", "report-metadata", id, "--source", "workstreams", "--clear-token", name)
	}
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

func (c Client) AdoptWorktree(ctx context.Context, root, path, label string) (model.Workspace, error) {
	var result struct {
		Workspace model.Workspace `json:"workspace"`
	}
	err := c.run(ctx, &result, "worktree", "open", "--cwd", root, "--path", path, "--label", label, "--no-focus")
	return result.Workspace, err
}

func (c Client) CreateWorktree(ctx context.Context, root, branch, label string) (model.Workspace, error) {
	var result struct {
		Workspace model.Workspace `json:"workspace"`
	}
	err := c.run(ctx, &result, "worktree", "create", "--cwd", root, "--branch", branch, "--label", label, "--no-focus")
	return result.Workspace, err
}

func (c Client) OpenPluginPalette(ctx context.Context) error {
	return c.run(ctx, nil, "plugin", "pane", "open", "--plugin", "workstreams", "--entrypoint", "palette", "--placement", "overlay", "--focus")
}

func (c Client) OpenPluginPane(ctx context.Context) error {
	return c.OpenPluginPaneMode(ctx, "")
}

func (c Client) OpenPluginPaneMode(ctx context.Context, mode string) error {
	args := []string{"plugin", "pane", "open", "--plugin", "workstreams", "--entrypoint", "overlay", "--placement", "overlay", "--focus"}
	if mode != "" {
		args = append(args, "--env", "WORKSTREAMS_MODE="+mode)
	}
	if workspace, err := c.Focused(ctx); err == nil && workspace.Worktree != nil {
		args = appendCWD(args, workspace.Worktree.CheckoutPath)
	} else {
		args = appendPluginCWD(args)
	}
	return c.run(ctx, nil, args...)
}
