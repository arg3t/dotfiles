package ui

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"charm.land/bubbles/v2/spinner"
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
	pauseMode
	restoreMode
	refsMode
)

type loadedMsg struct {
	workstreams []model.Workstream
	paused      []model.Paused
	err         error
}

type actionMsg struct {
	message     string
	workspaceID string
	err         error
}

type Overlay struct {
	ctx             context.Context
	herdr           herdr.Client
	store           store.Store
	service         worktree.Service
	mode            mode
	items           []model.Workstream
	paused          []model.Paused
	selected        int
	initialized     bool
	detailSelected  int
	pendingSelectID string
	input           textinput.Model
	spinner         spinner.Model
	busy            bool
	status          string
	width           int
	height          int
}

var (
	workstreamTitleStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#BB9AF7"))
	workstreamSelectStyle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#9ECE6A"))
	workstreamTextStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("#C0CAF5"))
	workstreamMutedStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#565F89"))
	workstreamErrorStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#F7768E"))
	workstreamWorkingStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#7DCFFF"))
	workstreamBlockedStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#E0AF68"))
)

func Run(ctx context.Context, client herdr.Client, state store.Store) error {
	input := textinput.New()
	input.Prompt = "Branch> "
	input.Placeholder = "feature/short-name"
	input.Focus()
	progress := spinner.New(spinner.WithSpinner(spinner.MiniDot))
	progress.Style = workstreamWorkingStyle
	model := Overlay{
		ctx:     ctx,
		herdr:   client,
		store:   state,
		service: worktree.Service{Herdr: client, Store: state},
		mode:    initialWorkstreamMode(os.Getenv("WORKSTREAMS_MODE")),
		input:   input,
		spinner: progress,
	}
	_, err := tea.NewProgram(model).Run()
	return err
}

func initialWorkstreamMode(value string) mode {
	switch value {
	case "create":
		return createMode
	case "pause":
		return pauseMode
	case "restore":
		return restoreMode
	case "refs":
		return refsMode
	default:
		return listMode
	}
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
		tabs, tabErr := m.herdr.Tabs(m.ctx, workspace.ID)
		if tabErr != nil {
			return loadedMsg{err: tabErr}
		}
		items = append(items, model.Workstream{
			Workspace:  workspace,
			Tabs:       tabs,
			Refs:       state.References[store.WorkstreamKey(*workspace.Worktree)],
			AgentState: model.AggregateState(panes),
		})
	}
	return loadedMsg{workstreams: items, paused: state.PausedRecords()}
}

func (m Overlay) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch value := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = value.Width, value.Height
	case spinner.TickMsg:
		if !m.busy {
			return m, nil
		}
		var command tea.Cmd
		m.spinner, command = m.spinner.Update(value)
		return m, command
	case loadedMsg:
		if value.err != nil {
			m.status = value.err.Error()
			return m, nil
		}
		m.items, m.paused = value.workstreams, value.paused
		m.selectPendingWorkspace()
		m.initialized = true
		return m, nil
	case actionMsg:
		m.busy = false
		if value.err != nil {
			m.status = value.err.Error()
			return m, nil
		}
		m.status = value.message
		m.pendingSelectID = value.workspaceID
		m.mode = listMode
		return m, m.load
	case tea.KeyPressMsg:
		if m.busy {
			return m, nil
		}
		if m.mode == createMode {
			return m.updateCreate(value)
		}
		if value.String() == "q" || value.String() == "esc" {
			if m.mode != listMode {
				m.mode = listMode
				m.detailSelected = 0
				return m, nil
			}
			return m, tea.Quit
		}
		switch value.String() {
		case "j", "down":
			m.move(1)
		case "k", "up":
			m.move(-1)
		case "n":
			m.mode = createMode
			m.input.SetValue("")
			m.status = ""
		case "p":
			m.mode = pauseMode
			m.status = "Select a workstream and press Enter to pause it"
		case "r":
			m.mode = restoreMode
			m.selected = 0
			m.status = "Select a paused workstream and press Enter to restore it"
		case "f":
			m.mode = refsMode
			m.detailSelected = 0
		case "enter":
			return m.activateSelection()
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
		m.status = "Creation cancelled"
		return m, nil
	}
	if key.String() == "enter" {
		branch := strings.TrimSpace(m.input.Value())
		if branch == "" {
			m.status = "Enter a branch name"
			return m, nil
		}
		m.busy = true
		m.status = "Creating workstream " + branch + "…"
		return m, tea.Batch(m.spinner.Tick, func() tea.Msg {
			source, err := m.herdr.Focused(m.ctx)
			if err != nil {
				return actionMsg{err: err}
			}
			created, err := m.service.Create(m.ctx, source, branch)
			if err != nil {
				return actionMsg{err: err}
			}
			return actionMsg{
				message:     fmt.Sprintf("Created %s using %s mode. Press Enter to focus it.", branch, created.Mode),
				workspaceID: created.Workspace.ID,
			}
		})
	}
	var command tea.Cmd
	m.input, command = m.input.Update(key)
	return m, command
}

func (m Overlay) activateSelection() (tea.Model, tea.Cmd) {
	switch m.mode {
	case restoreMode:
		if len(m.paused) == 0 || m.selected >= len(m.paused) {
			return m, nil
		}
		record := m.paused[m.selected]
		m.busy = true
		m.status = "Restoring " + record.Label + "…"
		return m, tea.Batch(m.spinner.Tick, func() tea.Msg {
			workspace, err := m.service.Restore(m.ctx, record.Key)
			return actionMsg{message: "Restored " + record.Label + ". Press Enter to focus it.", workspaceID: workspace.ID, err: err}
		})
	case pauseMode:
		item, ok := m.current()
		if !ok {
			return m, nil
		}
		m.busy = true
		m.status = "Pausing " + item.Workspace.Label + "…"
		return m, tea.Batch(m.spinner.Tick, func() tea.Msg {
			err := m.service.Pause(m.ctx, item.Workspace)
			return actionMsg{message: "Paused " + item.Workspace.Label, err: err}
		})
	case refsMode:
		return m, m.openReference
	default:
		item, ok := m.current()
		if !ok {
			return m, nil
		}
		return m, func() tea.Msg {
			return actionMsg{message: "Focused " + item.Workspace.Label, err: m.herdr.Focus(m.ctx, item.Workspace.ID)}
		}
	}
}

func (m *Overlay) selectPendingWorkspace() {
	if m.pendingSelectID != "" {
		for index, item := range m.items {
			if item.Workspace.ID == m.pendingSelectID {
				m.selected = index
				break
			}
		}
		m.pendingSelectID = ""
	} else if !m.initialized {
		for index, item := range m.items {
			if item.Workspace.Focused {
				m.selected = index
				break
			}
		}
	}
	if m.selected >= len(m.items) {
		m.selected = max(0, len(m.items)-1)
	}
}

func (m *Overlay) move(delta int) {
	if m.mode == restoreMode {
		m.selected = moveIndex(m.selected, delta, len(m.paused))
		return
	}
	if m.mode == refsMode {
		if item, ok := m.current(); ok {
			m.detailSelected = moveIndex(m.detailSelected, delta, len(visibleReferences(item.Refs)))
		}
		return
	}
	m.selected = moveIndex(m.selected, delta, len(m.items))
}

func moveIndex(index, delta, size int) int {
	if size == 0 {
		return 0
	}
	return (index + delta + size) % size
}

func (m Overlay) current() (model.Workstream, bool) {
	if len(m.items) == 0 || m.selected < 0 || m.selected >= len(m.items) {
		return model.Workstream{}, false
	}
	return m.items[m.selected], true
}

func (m Overlay) reference() (model.Workstream, model.Reference, bool) {
	item, ok := m.current()
	if !ok {
		return model.Workstream{}, model.Reference{}, false
	}
	references := visibleReferences(item.Refs)
	if len(references) == 0 || m.detailSelected >= len(references) {
		return model.Workstream{}, model.Reference{}, false
	}
	return item, references[m.detailSelected], true
}

func visibleReferences(references []model.Reference) []model.Reference {
	visible := make([]model.Reference, 0, len(references))
	for _, reference := range references {
		if !reference.Dismissed {
			visible = append(visible, reference)
		}
	}
	return visible
}

func (m Overlay) setReference(pinned, dismissed bool) tea.Msg {
	item, reference, ok := m.reference()
	if !ok {
		return actionMsg{err: fmt.Errorf("no reference selected")}
	}
	state, err := m.store.Load()
	if err == nil {
		state.SetReference(store.WorkstreamKey(*item.Workspace.Worktree), reference.Key(), pinned, dismissed)
		err = m.store.Save(state)
	}
	return actionMsg{message: "Updated " + reference.ID, workspaceID: item.Workspace.ID, err: err}
}

func (m Overlay) pinReference() tea.Msg     { return m.setReference(true, false) }
func (m Overlay) dismissReference() tea.Msg { return m.setReference(false, true) }

func (m Overlay) openReference() tea.Msg {
	_, reference, ok := m.reference()
	if !ok {
		return actionMsg{err: fmt.Errorf("no reference selected")}
	}
	if reference.URL == "" {
		return actionMsg{err: fmt.Errorf("reference %s has no URL", reference.ID)}
	}
	command := "xdg-open"
	if runtime.GOOS == "darwin" {
		command = "open"
	}
	return actionMsg{message: "Opened " + reference.URL, err: exec.Command(command, reference.URL).Run()}
}

func (m Overlay) View() tea.View {
	var output strings.Builder
	output.WriteString(workstreamTitleStyle.Render("Workstreams") + "\n")
	output.WriteString(workstreamMutedStyle.Render("One worktree-backed workspace is one workstream. Tabs are its execution surfaces.") + "\n\n")
	if m.status != "" {
		style := workstreamTextStyle
		if strings.Contains(strings.ToLower(m.status), "error") || strings.Contains(strings.ToLower(m.status), "failed") {
			style = workstreamErrorStyle
		}
		prefix := ""
		if m.busy {
			prefix = m.spinner.View() + " "
		}
		output.WriteString(style.Render(prefix+m.status) + "\n\n")
	}
	switch m.mode {
	case createMode:
		output.WriteString(workstreamTitleStyle.Render("Create a workstream") + "\n\n")
		output.WriteString(m.input.View() + "\n\n")
		output.WriteString(workstreamMutedStyle.Render("Enter create  ·  Esc cancel") + "\n")
	case restoreMode:
		m.renderPaused(&output)
	case refsMode:
		m.renderReferences(&output)
	default:
		m.renderWorkstreams(&output)
	}
	view := tea.NewView(output.String())
	view.AltScreen = true
	return view
}

func (m Overlay) renderWorkstreams(output *strings.Builder) {
	if len(m.items) == 0 {
		output.WriteString(workstreamMutedStyle.Render("No worktree-backed workspaces are open.") + "\n")
		output.WriteString(workstreamMutedStyle.Render("Press n to create one from the focused repository.") + "\n")
		return
	}
	for index, item := range m.items {
		selected := index == m.selected
		cursor := "  "
		label := workstreamTextStyle.Render(item.Workspace.Label)
		if selected {
			cursor = workstreamSelectStyle.Render("› ")
			label = workstreamSelectStyle.Render(item.Workspace.Label)
		}
		state := renderAgentState(item.AgentState)
		branch := ""
		if item.Workspace.Worktree != nil {
			branch = item.Workspace.Worktree.Branch
		}
		output.WriteString(cursor + state + "  " + label + "\n")
		output.WriteString("    " + workstreamMutedStyle.Render(fmt.Sprintf("branch %s  ·  %d tabs  ·  %d refs", branch, len(item.Tabs), len(visibleReferences(item.Refs)))) + "\n")
		if selected {
			for tabIndex, tab := range item.Tabs {
				connector := "├─"
				if tabIndex == len(item.Tabs)-1 {
					connector = "└─"
				}
				output.WriteString("    " + workstreamMutedStyle.Render(connector+" tab ") + workstreamTextStyle.Render(tab.Label) + "\n")
			}
		}
	}
	help := "↑/↓ select  ·  Enter focus  ·  n create  ·  p pause  ·  r restore  ·  f refs  ·  Esc close"
	if m.mode == pauseMode {
		help = "↑/↓ select  ·  Enter pause  ·  Esc back"
	}
	output.WriteString("\n" + workstreamMutedStyle.Render(help) + "\n")
}

func (m Overlay) renderPaused(output *strings.Builder) {
	output.WriteString(workstreamTitleStyle.Render("Paused workstreams") + "\n\n")
	if len(m.paused) == 0 {
		output.WriteString(workstreamMutedStyle.Render("No paused workstreams.") + "\n")
		return
	}
	for index, record := range m.paused {
		cursor := "  "
		label := workstreamTextStyle.Render(record.Label)
		if index == m.selected {
			cursor = workstreamSelectStyle.Render("› ")
			label = workstreamSelectStyle.Render(record.Label)
		}
		output.WriteString(cursor + label + "\n")
		output.WriteString("    " + workstreamMutedStyle.Render(record.Worktree.Branch+" · "+record.PausedAt.Local().Format("2006-01-02 15:04")) + "\n")
	}
	output.WriteString("\n" + workstreamMutedStyle.Render("↑/↓ select  ·  Enter restore  ·  Esc back") + "\n")
}

func (m Overlay) renderReferences(output *strings.Builder) {
	item, ok := m.current()
	if !ok {
		output.WriteString(workstreamMutedStyle.Render("No workstream selected.") + "\n")
		return
	}
	output.WriteString(workstreamTitleStyle.Render("References · "+item.Workspace.Label) + "\n\n")
	references := visibleReferences(item.Refs)
	if len(references) == 0 {
		output.WriteString(workstreamMutedStyle.Render("No references discovered yet.") + "\n")
		return
	}
	for index, reference := range references {
		cursor := "  "
		label := workstreamTextStyle.Render(reference.ID)
		if index == m.detailSelected {
			cursor = workstreamSelectStyle.Render("› ")
			label = workstreamSelectStyle.Render(reference.ID)
		}
		pin := ""
		if reference.Pinned {
			pin = "★ "
		}
		output.WriteString(cursor + pin + strings.ToUpper(string(reference.Kind)) + "  " + label + "\n")
	}
	output.WriteString("\n" + workstreamMutedStyle.Render("↑/↓ select  ·  Enter open  ·  Space pin  ·  x dismiss  ·  Esc back") + "\n")
}

func renderAgentState(state model.AgentState) string {
	switch state {
	case model.AgentWorking:
		return workstreamWorkingStyle.Render("WORKING")
	case model.AgentBlocked:
		return workstreamBlockedStyle.Render("BLOCKED")
	default:
		return workstreamMutedStyle.Render("IDLE   ")
	}
}
