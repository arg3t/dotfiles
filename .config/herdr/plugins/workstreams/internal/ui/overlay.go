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

type workstreamRow struct {
	workstream int
	tab        int
}

func (row workstreamRow) isTab() bool { return row.tab >= 0 }

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
	search          textinput.Model
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
	search := textinput.New()
	search.Prompt = "Search> "
	search.Placeholder = "titles, tabs, branches, repositories, refs, state"
	search.Blur()
	progress := spinner.New(spinner.WithSpinner(spinner.MiniDot))
	progress.Style = workstreamWorkingStyle
	model := Overlay{
		ctx:     ctx,
		herdr:   client,
		store:   state,
		service: worktree.Service{Herdr: client, Store: state},
		mode:    initialWorkstreamMode(os.Getenv("WORKSTREAMS_MODE")),
		input:   input,
		search:  search,
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
		if m.search.Focused() {
			switch value.String() {
			case "esc":
				m.search.Blur()
				return m, nil
			case "up", "ctrl+k":
				m.move(-1)
				return m, nil
			case "down", "ctrl+j":
				m.move(1)
				return m, nil
			case "left":
				m.jumpWorkstream(-1)
				return m, nil
			case "right":
				m.jumpWorkstream(1)
				return m, nil
			case "enter":
				return m.activateSelection()
			}
			var command tea.Cmd
			m.search, command = m.search.Update(value)
			m.clampSelectedRow()
			return m, command
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
		case "/":
			m.search.Focus()
			return m, m.search.Focus()
		case "j", "down":
			m.move(1)
		case "k", "up":
			m.move(-1)
		case "left":
			m.jumpWorkstream(-1)
		case "right":
			m.jumpWorkstream(1)
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
		row, ok := m.selectedRow()
		if !ok {
			return m, nil
		}
		item := m.items[row.workstream]
		if row.isTab() {
			tab := item.Tabs[row.tab]
			return m, func() tea.Msg {
				return actionMsg{message: "Focused tab " + tab.Label, err: m.herdr.FocusTab(m.ctx, tab.ID)}
			}
		}
		return m, func() tea.Msg {
			return actionMsg{message: "Focused " + item.Workspace.Label, err: m.herdr.Focus(m.ctx, item.Workspace.ID)}
		}
	}
}

func (m *Overlay) selectPendingWorkspace() {
	rows := m.workstreamRows()
	if m.pendingSelectID != "" {
		for index, row := range rows {
			if !row.isTab() && m.items[row.workstream].Workspace.ID == m.pendingSelectID {
				m.selected = index
				break
			}
		}
		m.pendingSelectID = ""
	} else if !m.initialized {
		for index, row := range rows {
			if !row.isTab() && m.items[row.workstream].Workspace.Focused {
				m.selected = index
				break
			}
		}
	}
	m.clampSelectedRow()
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
	m.selected = moveIndex(m.selected, delta, len(m.workstreamRows()))
}

func (m *Overlay) jumpWorkstream(delta int) {
	if m.mode == restoreMode || m.mode == createMode {
		return
	}
	rows := m.workstreamRows()
	if len(rows) == 0 {
		return
	}
	current, ok := m.selectedRow()
	if !ok {
		return
	}
	filtered := m.filteredWorkstreams()
	if len(filtered) == 0 {
		return
	}
	position := 0
	for index, workstreamIndex := range filtered {
		if workstreamIndex == current.workstream {
			position = index
			break
		}
	}
	target := (position + delta + len(filtered)) % len(filtered)
	for index, row := range rows {
		if !row.isTab() && row.workstream == filtered[target] {
			m.selected = index
			return
		}
	}
}

func moveIndex(index, delta, size int) int {
	if size == 0 {
		return 0
	}
	return (index + delta + size) % size
}

func (m *Overlay) clampSelectedRow() {
	rows := m.workstreamRows()
	if m.selected >= len(rows) {
		m.selected = max(0, len(rows)-1)
	}
}

func (m Overlay) selectedRow() (workstreamRow, bool) {
	rows := m.workstreamRows()
	if m.selected < 0 || m.selected >= len(rows) {
		return workstreamRow{}, false
	}
	return rows[m.selected], true
}

func (m Overlay) current() (model.Workstream, bool) {
	row, ok := m.selectedRow()
	if !ok || row.workstream < 0 || row.workstream >= len(m.items) {
		return model.Workstream{}, false
	}
	return m.items[row.workstream], true
}

func (m Overlay) workstreamRows() []workstreamRow {
	rows := make([]workstreamRow, 0)
	for _, workstreamIndex := range m.filteredWorkstreams() {
		rows = append(rows, workstreamRow{workstream: workstreamIndex, tab: -1})
		for tabIndex := range m.items[workstreamIndex].Tabs {
			rows = append(rows, workstreamRow{workstream: workstreamIndex, tab: tabIndex})
		}
	}
	return rows
}

func (m Overlay) filteredWorkstreams() []int {
	query := strings.ToLower(strings.TrimSpace(m.search.Value()))
	indices := make([]int, 0, len(m.items))
	for index, item := range m.items {
		if query == "" || strings.Contains(workstreamSearchText(item), query) {
			indices = append(indices, index)
		}
	}
	return indices
}

func workstreamSearchText(item model.Workstream) string {
	parts := []string{item.Workspace.Label, string(item.AgentState)}
	if item.Workspace.Worktree != nil {
		parts = append(parts, item.Workspace.Worktree.Branch, item.Workspace.Worktree.RepoName, item.Workspace.Worktree.RepoRoot, item.Workspace.Worktree.CheckoutPath)
	}
	for _, tab := range item.Tabs {
		parts = append(parts, tab.Label)
	}
	for _, reference := range visibleReferences(item.Refs) {
		parts = append(parts, string(reference.Kind), reference.ID, reference.URL)
	}
	return strings.ToLower(strings.Join(parts, " "))
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
	if m.mode != createMode && m.mode != restoreMode {
		output.WriteString(m.search.View() + "\n")
		if !m.search.Focused() {
			output.WriteString(workstreamMutedStyle.Render("Press / to search") + "\n")
		}
		output.WriteString("\n")
	}
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
	rows := m.workstreamRows()
	if len(m.items) == 0 {
		output.WriteString(workstreamMutedStyle.Render("No worktree-backed workspaces are open.") + "\n")
		output.WriteString(workstreamMutedStyle.Render("Press n to create one from the focused repository.") + "\n")
		return
	}
	if len(rows) == 0 {
		output.WriteString(workstreamMutedStyle.Render("No workstreams match the current search.") + "\n")
		return
	}
	for rowIndex, row := range rows {
		item := m.items[row.workstream]
		selected := rowIndex == m.selected
		cursor := "  "
		if selected {
			cursor = workstreamSelectStyle.Render("› ")
		}
		if !row.isTab() {
			label := workstreamTextStyle.Render(item.Workspace.Label)
			if selected {
				label = workstreamSelectStyle.Render(item.Workspace.Label)
			}
			branch := ""
			if item.Workspace.Worktree != nil {
				branch = item.Workspace.Worktree.Branch
			}
			output.WriteString(cursor + renderAgentState(item.AgentState) + "  " + label + "\n")
			output.WriteString("    " + workstreamMutedStyle.Render(fmt.Sprintf("branch %s  ·  %d tabs  ·  %d refs", branch, len(item.Tabs), len(visibleReferences(item.Refs)))) + "\n")
			continue
		}
		tab := item.Tabs[row.tab]
		connector := "├─"
		if row.tab == len(item.Tabs)-1 {
			connector = "└─"
		}
		label := workstreamTextStyle.Render(tab.Label)
		if selected {
			label = workstreamSelectStyle.Render(tab.Label)
		}
		output.WriteString(cursor + "  " + workstreamMutedStyle.Render(connector+" TAB ") + label + "\n")
	}
	help := "↑/↓ row  ·  ←/→ workstream  ·  Enter focus  ·  / search  ·  n create  ·  p pause  ·  r restore  ·  f refs  ·  Esc close"
	if m.mode == pauseMode {
		help = "↑/↓ row  ·  ←/→ workstream  ·  Enter pause  ·  / search  ·  Esc back"
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
