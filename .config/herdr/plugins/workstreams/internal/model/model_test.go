package model

import "testing"

func TestAggregateStatePrecedence(t *testing.T) {
	cases := []struct {
		name  string
		panes []Pane
		want  AgentState
	}{
		{name: "empty is idle", want: AgentIdle},
		{name: "blocked", panes: []Pane{{AgentState: AgentBlocked}}, want: AgentBlocked},
		{name: "working beats blocked", panes: []Pane{{AgentState: AgentBlocked}, {AgentState: AgentWorking}}, want: AgentWorking},
		{name: "idle when no active states", panes: []Pane{{AgentState: AgentIdle}}, want: AgentIdle},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if got := AggregateState(tc.panes); got != tc.want {
				t.Fatalf("AggregateState() = %q, want %q", got, tc.want)
			}
		})
	}
}
