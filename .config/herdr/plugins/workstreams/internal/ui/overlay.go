package ui

import (
	"context"
	"fmt"
	"os/exec"
	"strings"

	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/herdr"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/store"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/worktree"
)

type mode int

const (
	listMode mode = iota
	createMode
	restoreMode
	refsMode
)

type loadedMsg struct {
	workstreams []model.Workstream
	paused      []model.Paused
	err         error
}
type actionMsg struct {
	message string
	err     error
}

type Overlay struct {
	ctx      context.Context
	herdr    herdr.Client
	store    store.Store
	service  worktree.Service
	mode     mode
	items    []model.Workstream
	paused   []model.Paused
	selected int
	input    textinput.Model
	status   string
	height   int
}

func Run(ctx context.Context, client herdr.Client, state store.Store) error {
	input := textinput.New()
	input.Prompt = "branch> "
	input.Placeholder = "feature/short-name"
	input.Focus()
	program := tea.NewProgram(newOverlay(ctx, client, state, input))
	_, err := program.Run()
	return err
}

func newOverlay(ctx context.Context, client herdr.Client, state store.Store, input textinput.Model) Overlay {
	return Overlay{ctx: ctx, herdr: client, store: state, service: worktree.Service{Herdr: client, Store: state}, input: input}
}
func (m Overlay) Init() tea.Cmd { return m.load }
func (m Overlay) load() tea.Msg {
	workspaces, err := m.herdr.Workspaces(m.ctx)
	if err != nil {
		return loadedMsg{err: err}
	}
	state, err := m.store.Load()
	if err != nil {
		return loadedMsg{err: err}
	}
	items := make([]model.Workstream, 0, len(workspaces))
	for _, workspace := range workspaces {
		if workspace.Worktree == nil {
			continue
		}
		panes, paneErr := m.herdr.Panes(m.ctx, workspace.ID)
		if paneErr != nil {
			return loadedMsg{err: paneErr}
		}
		items = append(items, model.Workstream{
			Workspace:  workspace,
			Refs:       state.References[store.WorkstreamKey(*workspace.Worktree)],
			AgentState: model.AggregateState(panes),
		})
	}
	return loadedMsg{workstreams: items, paused: state.PausedRecords()}
}
func (m Overlay) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch v := msg.(type) {
	case tea.WindowSizeMsg:
		m.height = v.Height
	case loadedMsg:
		if v.err != nil {
			m.status = v.err.Error()
		} else {
			m.items, m.paused, m.selected = v.workstreams, v.paused, 0
			m.status = ""
		}
		return m, nil
	case actionMsg:
		if v.err != nil {
			m.status = v.err.Error()
		} else {
			m.status = v.message
		}
		return m, m.load
	case tea.KeyPressMsg:
		if m.mode == createMode {
			return m.updateCreate(v)
		}
		if v.String() == "q" || v.String() == "esc" {
			return m, tea.Quit
		}
		switch v.String() {
		case "j", "down":
			m.move(1)
		case "k", "up":
			m.move(-1)
		case "n":
			m.mode = createMode
			m.input.SetValue("")
		case "p":
			return m, m.pauseSelected
		case "r":
			m.mode = restoreMode
			m.selected = 0
		case "a":
			m.mode = listMode
		case "enter":
			if m.mode == restoreMode {
				return m, m.restoreSelected
			}
			if m.mode == refsMode {
				return m, m.openReference
			}
			if item, ok := m.current(); ok {
				return m, func() tea.Msg {
					return actionMsg{message: "focused " + item.Workspace.Label, err: m.herdr.Focus(m.ctx, item.Workspace.ID)}
				}
			}
		case "f":
			if m.mode == listMode {
				m.mode = refsMode
				m.selected = 0
			}
		case "x":
			if m.mode == refsMode {
				return m, m.dismissReference
			}
		case "space":
			if m.mode == refsMode {
				return m, m.pinReference
			}
		}
	}
	return m, nil
}
func (m Overlay) updateCreate(key tea.KeyPressMsg) (tea.Model, tea.Cmd) {
	if key.String() == "esc" {
		m.mode = listMode
		return m, nil
	}
	if key.String() == "enter" {
		branch := strings.TrimSpace(m.input.Value())
		m.mode = listMode
		return m, func() tea.Msg {
			source, err := m.herdr.Focused(m.ctx)
			if err == nil {
				_, err = m.service.Create(m.ctx, source, branch)
			}
			return actionMsg{message: "created " + branch, err: err}
		}
	}
	var cmd tea.Cmd
	m.input, cmd = m.input.Update(key)
	return m, cmd
}
func (m *Overlay) move(delta int) {
	size := len(m.items)
	if m.mode == restoreMode {
		size = len(m.paused)
	}
	if m.mode == refsMode {
		if item, ok := m.current(); ok {
			size = len(item.Refs)
		}
	}
	if size == 0 {
		m.selected = 0
		return
	}
	m.selected = (m.selected + delta + size) % size
}
func (m Overlay) current() (model.Workstream, bool) {
	if len(m.items) == 0 || m.selected < 0 || m.selected >= len(m.items) {
		return model.Workstream{}, false
	}
	return m.items[m.selected], true
}
func (m Overlay) pauseSelected() tea.Msg {
	item, ok := m.current()
	if !ok {
		return actionMsg{err: fmt.Errorf("no workstream selected")}
	}
	return actionMsg{message: "paused " + item.Workspace.Label, err: m.service.Pause(m.ctx, item.Workspace)}
}
func (m Overlay) restoreSelected() tea.Msg {
	if len(m.paused) == 0 || m.selected >= len(m.paused) {
		return actionMsg{err: fmt.Errorf("no paused workstream selected")}
	}
	_, err := m.service.Restore(m.ctx, m.paused[m.selected].Key)
	return actionMsg{message: "restored " + m.paused[m.selected].Label, err: err}
}
func (m Overlay) reference() (model.Workstream, model.Reference, bool) {
	item, ok := m.current()
	if !ok || len(item.Refs) == 0 || m.selected >= len(item.Refs) {
		return model.Workstream{}, model.Reference{}, false
	}
	return item, item.Refs[m.selected], true
}
func (m Overlay) setRef(pinned, dismissed bool) tea.Msg {
	item, ref, ok := m.reference()
	if !ok {
		return actionMsg{err: fmt.Errorf("no reference selected")}
	}
	state, err := m.store.Load()
	if err == nil {
		state.SetReference(store.WorkstreamKey(*item.Workspace.Worktree), ref.Key(), pinned, dismissed)
		err = m.store.Save(state)
	}
	return actionMsg{message: "updated " + ref.ID, err: err}
}
func (m Overlay) pinReference() tea.Msg     { return m.setRef(true, false) }
func (m Overlay) dismissReference() tea.Msg { return m.setRef(false, true) }
func (m Overlay) openReference() tea.Msg {
	_, ref, ok := m.reference()
	if !ok {
		return actionMsg{err: fmt.Errorf("no reference selected")}
	}
	if ref.URL == "" {
		return actionMsg{err: fmt.Errorf("reference %s has no URL", ref.ID)}
	}
	return actionMsg{message: "opened " + ref.URL, err: exec.Command("open", ref.URL).Run()}
}
func (m Overlay) View() tea.View {
	var b strings.Builder
	title := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("69")).Render("Workstreams")
	b.WriteString(title + "\n")
	if m.status != "" {
		b.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("9")).Render(m.status) + "\n")
	}
	if m.mode == createMode {
		b.WriteString("Create a fast worktree\n\n")
		b.WriteString(m.input.View())
		b.WriteString("\n\nenter create · esc cancel\n")
		return tea.NewView(b.String())
	}
	if m.mode == restoreMode {
		b.WriteString("Paused workstreams\n\n")
		for i, record := range m.paused {
			b.WriteString(cursor(i == m.selected) + record.Label + "  " + record.Worktree.Branch + "\n")
		}
		b.WriteString("\nenter restore · esc close\n")
		return tea.NewView(b.String())
	}
	if m.mode == refsMode {
		item, ok := m.current()
		if !ok {
			b.WriteString("No references\n")
			return tea.NewView(b.String())
		}
		b.WriteString("References for " + item.Workspace.Label + "\n\n")
		for i, ref := range item.Refs {
			if ref.Dismissed {
				continue
			}
			mark := ""
			if ref.Pinned {
				mark = "★ "
			}
			b.WriteString(cursor(i == m.selected) + mark + string(ref.Kind) + ": " + ref.ID + "\n")
		}
		b.WriteString("\nenter open · space pin · x dismiss · esc close\n")
		return tea.NewView(b.String())
	}
	b.WriteString("\n")
	for i, item := range m.items {
		branch := ""
		if item.Workspace.Worktree != nil {
			branch = item.Workspace.Worktree.Branch
		}
		b.WriteString(cursor(i == m.selected) + item.Workspace.Label + "  [" + string(item.AgentState) + "]  " + branch + "\n")
	}
	b.WriteString("\nn new · p pause · r restore · f refs · enter focus · q close\n")
	return tea.NewView(b.String())
}
func cursor(selected bool) string {
	if selected {
		return "› "
	}
	return "  "
}
