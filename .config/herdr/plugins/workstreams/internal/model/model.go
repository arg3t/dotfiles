package model

import "time"

type AgentState string

const (
	AgentWorking AgentState = "working"
	AgentBlocked AgentState = "blocked"
	AgentIdle    AgentState = "idle"
)

type Worktree struct {
	CheckoutPath string `json:"checkout_path"`
	RepoRoot     string `json:"repo_root"`
	RepoName     string `json:"repo_name"`
	Branch       string `json:"branch"`
}

type Workspace struct {
	ID       string            `json:"workspace_id"`
	Number   int               `json:"number"`
	Label    string            `json:"label"`
	Focused  bool              `json:"focused"`
	Worktree *Worktree         `json:"worktree,omitempty"`
	Tokens   map[string]string `json:"tokens,omitempty"`
}

type Tab struct {
	ID          string `json:"tab_id"`
	WorkspaceID string `json:"workspace_id"`
	Label       string `json:"label"`
}

type Pane struct {
	ID            string     `json:"pane_id"`
	WorkspaceID   string     `json:"workspace_id"`
	TabID         string     `json:"tab_id"`
	CWD           string     `json:"cwd"`
	ForegroundCWD string     `json:"foreground_cwd"`
	Focused       bool       `json:"focused"`
	AgentState    AgentState `json:"agent_status"`
}

type ReferenceKind string

const (
	ReferenceJira ReferenceKind = "jira"
	ReferencePR   ReferenceKind = "pr"
	ReferenceURL  ReferenceKind = "url"
)

type Reference struct {
	Kind       ReferenceKind `json:"kind"`
	ID         string        `json:"id"`
	URL        string        `json:"url,omitempty"`
	Pinned     bool          `json:"pinned,omitempty"`
	Dismissed  bool          `json:"dismissed,omitempty"`
	Discovered time.Time     `json:"discovered"`
}

func (r Reference) Key() string { return string(r.Kind) + ":" + r.ID }

type Paused struct {
	Version     int               `json:"version"`
	Key         string            `json:"key"`
	Label       string            `json:"label"`
	Worktree    Worktree          `json:"worktree"`
	Tabs        []string          `json:"tabs"`
	Tokens      map[string]string `json:"tokens"`
	References  []Reference       `json:"references"`
	TitleLocked bool              `json:"title_locked"`
	PausedAt    time.Time         `json:"paused_at"`
}

type Workstream struct {
	Workspace  Workspace
	Tabs       []Tab
	Refs       []Reference
	AgentState AgentState
	Paused     bool
}

func AggregateState(panes []Pane) AgentState {
	for _, pane := range panes {
		if pane.AgentState == AgentWorking {
			return AgentWorking
		}
	}
	for _, pane := range panes {
		if pane.AgentState == AgentBlocked {
			return AgentBlocked
		}
	}
	return AgentIdle
}
