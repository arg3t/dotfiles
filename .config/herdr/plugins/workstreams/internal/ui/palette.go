package ui

import (
	"context"
	"fmt"
	"os"
	"strings"

	"charm.land/bubbles/v2/textinput"
	tea "charm.land/bubbletea/v2"
	"charm.land/lipgloss/v2"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/herdr"
)

type paletteKind string

type nativeAction string

const (
	paletteNative    paletteKind = "native"
	paletteWorkspace paletteKind = "workspace"
	paletteTab       paletteKind = "tab"
	palettePlugin    paletteKind = "plugin"

	nativeNewWorkspace nativeAction = "new-workspace"
	nativeNewTab       nativeAction = "new-tab"
	nativeSplitRight   nativeAction = "split-right"
	nativeSplitDown    nativeAction = "split-down"
	nativeToggleZoom   nativeAction = "toggle-zoom"
)

type paletteItem struct {
	kind        paletteKind
	title       string
	description string
	context     string
	search      string
	id          string
	native      nativeAction
	plugin      herdr.PluginAction
}

type paletteLoaded struct {
	items []paletteItem
	err   error
}

type paletteResult struct {
	message string
	err     error
}

type palette struct {
	ctx      context.Context
	client   herdr.Client
	cwd      string
	input    textinput.Model
	items    []paletteItem
	visible  []paletteItem
	selected int
	status   string
}

var (
	paletteTitleStyle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#BB9AF7"))
	paletteBadgeStyle  = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#7DCFFF")).Width(11)
	paletteItemStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#C0CAF5"))
	paletteMetaStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#565F89"))
	paletteSelectStyle = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#9ECE6A"))
	paletteErrorStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("#F7768E"))
)

func RunPalette(ctx context.Context, client herdr.Client) error {
	cwd := os.Getenv("HERDR_WORKSPACE_CWD")
	if cwd == "" {
		var err error
		cwd, err = os.Getwd()
		if err != nil {
			return err
		}
	}
	input := textinput.New()
	input.Prompt = "› "
	input.Placeholder = "Search actions, workspaces, and tabs"
	input.Focus()
	_, programErr := tea.NewProgram(palette{ctx: ctx, client: client, cwd: cwd, input: input}).Run()
	return programErr
}

func (m palette) Init() tea.Cmd { return m.load }

func (m palette) load() tea.Msg {
	workspaces, err := m.client.Workspaces(m.ctx)
	if err != nil {
		return paletteLoaded{err: err}
	}
	plugins, err := m.client.PluginActions(m.ctx)
	if err != nil {
		return paletteLoaded{err: err}
	}
	items := nativePaletteItems()
	for _, workspace := range workspaces {
		items = append(items, newPaletteItem(paletteWorkspace, workspace.Label, "Focus this workspace", workspace.ID, workspace.ID))
		tabs, tabErr := m.client.Tabs(m.ctx, workspace.ID)
		if tabErr != nil {
			return paletteLoaded{err: tabErr}
		}
		for _, tab := range tabs {
			items = append(items, newPaletteItem(paletteTab, tab.Label, "Focus this tab", workspace.Label, tab.ID))
		}
	}
	for _, action := range plugins {
		if action.PluginID == "workstreams" && action.ID == "palette" {
			continue
		}
		item := newPaletteItem(palettePlugin, action.Title, pluginActionDescription(action), action.PluginID, action.ID)
		item.plugin = action
		items = append(items, item)
	}
	return paletteLoaded{items: items}
}

func pluginActionDescription(action herdr.PluginAction) string {
	if action.PluginID != "workstreams" {
		return "Run plugin action"
	}
	switch action.ID {
	case "open":
		return "Open the workstream manager"
	case "create":
		return "Create a worktree-backed workspace"
	case "pause":
		return "Close a workstream while keeping its worktree"
	case "restore":
		return "Reopen a paused workstream"
	case "refs":
		return "Browse discovered Jira, PR, and URL references"
	default:
		return "Run Workstreams action"
	}
}

func nativePaletteItems() []paletteItem {
	return []paletteItem{
		newNativeItem(nativeNewWorkspace, "New workspace", "Create and focus a workspace at the current directory"),
		newNativeItem(nativeNewTab, "New tab", "Create a tab in the focused workspace"),
		newNativeItem(nativeSplitRight, "Split pane right", "Create a horizontal pane split"),
		newNativeItem(nativeSplitDown, "Split pane down", "Create a vertical pane split"),
		newNativeItem(nativeToggleZoom, "Toggle pane zoom", "Zoom or restore the current pane"),
	}
}

func newNativeItem(action nativeAction, title, description string) paletteItem {
	item := newPaletteItem(paletteNative, title, description, "Herdr", string(action))
	item.native = action
	return item
}

func newPaletteItem(kind paletteKind, title, description, context, id string) paletteItem {
	search := strings.ToLower(strings.Join([]string{string(kind), title, description, context, id}, " "))
	return paletteItem{kind: kind, title: title, description: description, context: context, id: id, search: search}
}

func (m *palette) filter() {
	query := strings.ToLower(strings.TrimSpace(m.input.Value()))
	m.visible = m.visible[:0]
	for _, item := range m.items {
		if query == "" || strings.Contains(item.search, query) {
			m.visible = append(m.visible, item)
		}
	}
	if m.selected >= len(m.visible) {
		m.selected = len(m.visible) - 1
	}
	if m.selected < 0 {
		m.selected = 0
	}
}

func (m palette) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch value := message.(type) {
	case paletteLoaded:
		if value.err != nil {
			m.status = value.err.Error()
			return m, nil
		}
		m.items = value.items
		m.filter()
		return m, nil
	case paletteResult:
		if value.err != nil {
			m.status = value.err.Error()
			return m, nil
		}
		return m, tea.Quit
	case tea.KeyPressMsg:
		switch value.String() {
		case "esc", "ctrl+c":
			return m, tea.Quit
		case "up", "ctrl+k":
			if m.selected > 0 {
				m.selected--
			}
			return m, nil
		case "down", "ctrl+j":
			if m.selected+1 < len(m.visible) {
				m.selected++
			}
			return m, nil
		case "enter":
			if len(m.visible) == 0 {
				return m, nil
			}
			item := m.visible[m.selected]
			return m, func() tea.Msg { return m.execute(item) }
		}
		var command tea.Cmd
		m.input, command = m.input.Update(value)
		m.filter()
		return m, command
	}
	return m, nil
}

func (m palette) execute(item paletteItem) paletteResult {
	var err error
	switch item.kind {
	case paletteNative:
		err = m.executeNative(item.native)
	case paletteWorkspace:
		err = m.client.Focus(m.ctx, item.id)
	case paletteTab:
		err = m.client.FocusTab(m.ctx, item.id)
	case palettePlugin:
		err = m.client.InvokePluginAction(m.ctx, item.plugin)
	default:
		err = fmt.Errorf("unknown palette item type %q", item.kind)
	}
	return paletteResult{message: item.title, err: err}
}

func (m palette) executeNative(action nativeAction) error {
	switch action {
	case nativeNewWorkspace:
		return m.client.CreateWorkspace(m.ctx, m.cwd)
	case nativeNewTab:
		workspace, err := m.client.Focused(m.ctx)
		if err != nil {
			return err
		}
		return m.client.CreateTabAt(m.ctx, workspace.ID, m.cwd)
	case nativeSplitRight:
		return m.client.SplitCurrent(m.ctx, "right", m.cwd)
	case nativeSplitDown:
		return m.client.SplitCurrent(m.ctx, "down", m.cwd)
	case nativeToggleZoom:
		return m.client.ToggleCurrentZoom(m.ctx)
	default:
		return fmt.Errorf("unknown native action %q", action)
	}
}

func (m palette) View() tea.View {
	var output strings.Builder
	output.WriteString(paletteTitleStyle.Render("Herdr Palette") + "\n")
	output.WriteString(paletteMetaStyle.Render("Actions, workspaces, and tabs in one place") + "\n\n")
	output.WriteString(m.input.View() + "\n\n")
	if m.status != "" {
		output.WriteString(paletteErrorStyle.Render(m.status) + "\n\n")
	}
	if len(m.visible) == 0 {
		output.WriteString(paletteMetaStyle.Render("No matching commands or destinations") + "\n")
	}
	for index, item := range m.visible {
		selected := index == m.selected
		cursor := "  "
		title := paletteItemStyle.Render(item.title)
		if selected {
			cursor = paletteSelectStyle.Render("› ")
			title = paletteSelectStyle.Render(item.title)
		}
		badge := paletteBadgeStyle.Render(strings.ToUpper(string(item.kind)))
		output.WriteString(cursor + badge + title + "\n")
		output.WriteString("  " + strings.Repeat(" ", 11) + paletteMetaStyle.Render(item.description+" · "+item.context) + "\n")
	}
	output.WriteString("\n" + paletteMetaStyle.Render("↑/↓ select  ·  Enter run/open  ·  type to filter  ·  Esc close") + "\n")
	view := tea.NewView(output.String())
	view.AltScreen = true
	return view
}
