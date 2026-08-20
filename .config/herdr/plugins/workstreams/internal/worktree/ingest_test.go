package worktree

import "testing"

func TestAutoRenameAllowed(t *testing.T) {
	tests := []struct {
		name          string
		current       string
		lastAutomatic string
		locked        bool
		wantAllowed   bool
		wantLocked    bool
	}{
		{name: "first title", current: "workspace", wantAllowed: true},
		{name: "still automatic", current: "generated", lastAutomatic: "generated", wantAllowed: true},
		{name: "manual rename locks", current: "my label", lastAutomatic: "generated", wantAllowed: false, wantLocked: true},
		{name: "existing lock stays", current: "generated", lastAutomatic: "generated", locked: true, wantAllowed: false, wantLocked: true},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			allowed, locked := autoRenameAllowed(test.current, test.lastAutomatic, test.locked)
			if allowed != test.wantAllowed || locked != test.wantLocked {
				t.Fatalf("autoRenameAllowed() = (%v, %v), want (%v, %v)", allowed, locked, test.wantAllowed, test.wantLocked)
			}
		})
	}
}
