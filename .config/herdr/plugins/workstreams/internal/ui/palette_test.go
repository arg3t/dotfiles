package ui

import "testing"

func TestNativePaletteItemsAreClearAndUnique(t *testing.T) {
	items := nativePaletteItems()
	if len(items) < 5 {
		t.Fatalf("nativePaletteItems() returned %d items, want at least 5", len(items))
	}
	seen := map[string]bool{}
	for _, item := range items {
		if item.kind != paletteNative {
			t.Fatalf("item %q has kind %q, want native", item.title, item.kind)
		}
		if item.title == "" || item.description == "" || item.context != "Herdr" {
			t.Fatalf("item is not self-describing: %#v", item)
		}
		if seen[item.id] {
			t.Fatalf("duplicate native action id %q", item.id)
		}
		seen[item.id] = true
	}
}

func TestPaletteSearchIncludesContextAndDescription(t *testing.T) {
	item := newPaletteItem(paletteTab, "Tests", "Focus this tab", "api workspace", "tab-1")
	for _, query := range []string{"tests", "focus", "api workspace", "tab-1"} {
		if !containsSearch(item.search, query) {
			t.Fatalf("search %q does not match %q", item.search, query)
		}
	}
}

func containsSearch(search, query string) bool {
	for start := 0; start+len(query) <= len(search); start++ {
		if search[start:start+len(query)] == query {
			return true
		}
	}
	return false
}
