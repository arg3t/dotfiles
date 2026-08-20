package ui

import "testing"

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
