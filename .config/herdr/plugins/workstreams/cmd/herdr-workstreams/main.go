package main

import (
	"context"
	"flag"
	"fmt"
	"os"

	"github.com/arg3t/dotfiles/herdr-workstreams/internal/herdr"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/store"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/ui"
	"github.com/arg3t/dotfiles/herdr-workstreams/internal/worktree"
)

func main() {
	ctx := context.Background()
	client, state := herdr.New(), store.New(os.Getenv("HERDR_PLUGIN_STATE_DIR"))
	args := os.Args[1:]
	if len(args) == 0 {
		fail("usage: herdr-workstreams overlay|palette|plugin <open|palette>|pause-focused")
	}
	switch args[0] {
	case "overlay":
		if err := ui.Run(ctx, client, state); err != nil {
			fail(err.Error())
		}
	case "palette":
		if err := ui.RunPalette(ctx, client); err != nil {
			fail(err.Error())
		}
	case "plugin":
		if len(args) != 2 {
			fail("usage: herdr-workstreams plugin <open|palette>")
		}
		var err error
		switch args[1] {
		case "open":
			err = client.OpenPluginPane(ctx)
		case "palette":
			err = client.OpenPluginPalette(ctx)
		default:
			fail("usage: herdr-workstreams plugin <open|palette>")
		}
		if err != nil {
			fail(err.Error())
		}
	case "pause-focused":
		workspace, err := client.Focused(ctx)
		if err == nil {
			err = (worktree.Service{Herdr: client, Store: state}).Pause(ctx, workspace)
		}
		if err != nil {
			fail(err.Error())
		}
	case "ingest":
		ingest(ctx, client, state, args[1:])
	default:
		fail("unknown command: " + args[0])
	}
}
func fail(message string) { fmt.Fprintln(os.Stderr, "workstreams:", message); os.Exit(1) }
func ingest(ctx context.Context, client herdr.Client, state store.Store, args []string) {
	flags := flag.NewFlagSet("ingest", flag.ContinueOnError)
	cwd := flags.String("cwd", "", "OMP working directory")
	title := flags.String("title", "", "OMP session title")
	text := flags.String("text", "", "text to extract references from")
	if err := flags.Parse(args); err != nil || *cwd == "" {
		fail("usage: herdr-workstreams ingest --cwd PATH [--title TITLE] [--text TEXT]")
	}
	if err := worktree.Ingest(ctx, client, state, *cwd, *title, *text); err != nil {
		fail(err.Error())
	}
}
