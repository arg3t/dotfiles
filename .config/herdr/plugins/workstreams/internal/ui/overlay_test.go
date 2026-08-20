package ui

import (
	"testing"

	"charm.land/bubbles/v2/textinput"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/model"
)

func TestInitialWorkstreamModes(t *testing.T) {
	cases := map[string]mode{
		"":        listMode,
		"create":  createMode,
		"pause":   pauseMode,
		"restore": restoreMode,
		"refs":    refsMode,
	}
	for input, want := range cases {
		if got := initialWorkstreamMode(input); got != want {
			t.Fatalf("initialWorkstreamMode(%q) = %v, want %v", input, got, want)
		}
	}
}

func TestWorkstreamsUsesAlternateScreen(t *testing.T) {
	view := (Overlay{}).View()
	if !view.AltScreen {
		t.Fatal("Workstreams must use the alternate screen to avoid duplicate input rendering")
	}
}

func TestPaletteUsesAlternateScreen(t *testing.T) {
	view := (palette{}).View()
	if !view.AltScreen {
		t.Fatal("palette must use the alternate screen to avoid duplicate input rendering")
	}
}

func TestWorkstreamRowsAlwaysIncludeTabs(t *testing.T) {
	overlay := Overlay{items: []model.Workstream{{
		Workspace: model.Workspace{Label: "API"},
		Tabs:      []model.Tab{{Label: "server"}, {Label: "tests"}},
	}}}
	rows := overlay.workstreamRows()
	if len(rows) != 3 || rows[0].isTab() || !rows[1].isTab() || !rows[2].isTab() {
		t.Fatalf("workstreamRows() = %#v, want one workstream followed by two tabs", rows)
	}
}

func TestWorkstreamSearchMatchesTabsAndReferences(t *testing.T) {
	search := textinput.New()
	overlay := Overlay{
		search: search,
		items: []model.Workstream{
			{Workspace: model.Workspace{Label: "API"}, Tabs: []model.Tab{{Label: "integration-tests"}}},
			{Workspace: model.Workspace{Label: "Web"}, Refs: []model.Reference{{Kind: model.ReferenceJira, ID: "WEB-42"}}},
		},
	}
	overlay.search.SetValue("integration")
	if rows := overlay.workstreamRows(); len(rows) != 2 || rows[0].workstream != 0 {
		t.Fatalf("tab search returned %#v", rows)
	}
	overlay.search.SetValue("web-42")
	if rows := overlay.workstreamRows(); len(rows) != 1 || rows[0].workstream != 1 {
		t.Fatalf("reference search returned %#v", rows)
	}
}

func TestJumpWorkstreamSkipsTabs(t *testing.T) {
	overlay := Overlay{items: []model.Workstream{
		{Workspace: model.Workspace{Label: "one"}, Tabs: []model.Tab{{Label: "one-a"}, {Label: "one-b"}}},
		{Workspace: model.Workspace{Label: "two"}, Tabs: []model.Tab{{Label: "two-a"}}},
	}}
	overlay.selected = 1
	overlay.jumpWorkstream(1)
	row, ok := overlay.selectedRow()
	if !ok || row.workstream != 1 || row.isTab() {
		t.Fatalf("right jump selected %#v, want second workstream header", row)
	}
}
