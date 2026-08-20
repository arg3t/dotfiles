package store

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
)

const Version = 1

type State struct {
	Version        int                          `json:"version"`
	References     map[string][]model.Reference `json:"references"`
	Paused         map[string]model.Paused      `json:"paused"`
	AutoLabels     map[string]string            `json:"auto_labels"`
	TitleLocked    map[string]bool              `json:"title_locked"`
	TabAutoLabels  map[string]string            `json:"tab_auto_labels"`
	TabTitleLocked map[string]bool              `json:"tab_title_locked"`
}

type Store struct{ Path string }

func New(path string) Store {
	if path == "" {
		home, _ := os.UserHomeDir()
		path = filepath.Join(home, ".local", "state", "herdr", "plugins", "workstreams")
	}
	return Store{Path: filepath.Join(path, "state.json")}
}

func (s Store) Load() (State, error) {
	state := State{Version: Version, References: map[string][]model.Reference{}, Paused: map[string]model.Paused{}, AutoLabels: map[string]string{}, TitleLocked: map[string]bool{}, TabAutoLabels: map[string]string{}, TabTitleLocked: map[string]bool{}}
	data, err := os.ReadFile(s.Path)
	if os.IsNotExist(err) {
		return state, nil
	}
	if err != nil {
		return State{}, err
	}
	if err := json.Unmarshal(data, &state); err != nil {
		return State{}, fmt.Errorf("decode %s: %w", s.Path, err)
	}
	if state.Version != Version {
		return State{}, fmt.Errorf("unsupported workstreams state version %d", state.Version)
	}
	if state.References == nil {
		state.References = map[string][]model.Reference{}
	}
	if state.Paused == nil {
		state.Paused = map[string]model.Paused{}
	}
	if state.AutoLabels == nil {
		state.AutoLabels = map[string]string{}
	}
	if state.TitleLocked == nil {
		state.TitleLocked = map[string]bool{}
	}
	if state.TabAutoLabels == nil {
		state.TabAutoLabels = map[string]string{}
	}
	if state.TabTitleLocked == nil {
		state.TabTitleLocked = map[string]bool{}
	}
	return state, nil
}

func (s Store) Save(state State) error {
	state.Version = Version
	if err := os.MkdirAll(filepath.Dir(s.Path), 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(state, "", "  ")
	if err != nil {
		return err
	}
	tmp := s.Path + ".tmp"
	if err := os.WriteFile(tmp, append(data, '\n'), 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, s.Path)
}

func WorkstreamKey(worktree model.Worktree) string {
	return filepath.Clean(worktree.RepoRoot) + "\x00" + filepath.Clean(worktree.CheckoutPath)
}

func PauseKey(worktree model.Worktree) string {
	key := worktree.RepoName + "-" + worktree.Branch
	key = strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '-' || r == '_' || r == '.' {
			return r
		}
		return '-'
	}, key)
	return strings.Trim(key, "-")
}

func (state *State) AddReference(key string, reference model.Reference) bool {
	refs := state.References[key]
	for i := range refs {
		if refs[i].Key() != reference.Key() {
			continue
		}
		if refs[i].Dismissed {
			return false
		}
		if reference.URL != "" {
			refs[i].URL = reference.URL
		}
		state.References[key] = refs
		return false
	}
	state.References[key] = append(refs, reference)
	return true
}

func (state *State) SetReference(key, refKey string, pinned, dismissed bool) bool {
	refs := state.References[key]
	for i := range refs {
		if refs[i].Key() != refKey {
			continue
		}
		refs[i].Pinned, refs[i].Dismissed = pinned, dismissed
		state.References[key] = refs
		return true
	}
	return false
}

func (state State) PausedRecords() []model.Paused {
	out := make([]model.Paused, 0, len(state.Paused))
	for _, record := range state.Paused {
		out = append(out, record)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].PausedAt.After(out[j].PausedAt) })
	return out
}
