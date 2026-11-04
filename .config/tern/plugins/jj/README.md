# jj

A [Jujutsu](https://jj-vcs.github.io/jj/) change tree for [Tern](https://stencil.so/tern), in the spirit of [VisualJJ](https://www.visualjj.com). The block draws the `jj log` graph as lines, rounded elbows and nodes in theme colors, and you shape changes with the pointer: click, double-click and right-click.

Each change shows its description, then badges for its workspaces (`default@`), bookmarks and tags, then its change id, author and age. The working copy is a filled node, immutable changes are diamonds, and conflicts are red.

## Install

```sh
tern plugin link ~/.dots/.config/tern/plugins/jj
```

Tern reloads the plugin each time you save a file in this folder. The block runs `jj` on the machine that runs your panes, so `jj` must be on its `PATH`.

## Using it

Focus a shell in a jj repo and run **New jj block** from the palette. The block opens beside the shell, on that shell's directory.

| Do | How |
| --- | --- |
| See a change's files | Click it. The right side shows its description and its changed files (A added, M modified, D deleted, R renamed) |
| See a file's diff | Click the file. A **jj diff** block opens beside the tree with the file's diff in a card: `+N −M`, word-level highlights and syntax colors. Later clicks show their file in that same block, which follows new edits |
| Diff side by side | Auto, Unified or Split in the diff card's head. Auto follows Tern's Settings › Edits; the choice is kept for every diff block |
| Open a file | Double-click it in the file list |
| Edit a change | Double-click it (`jj edit`) |
| Shape a change | Right-click it: New change here, Describe…, Squash into parent, Split…, Rebase on trunk, Duplicate, Revert, Push, Abandon, Abandon with descendants |
| Rebase a change | Right-click › Move…, then click the new parent (`jj rebase -s`). Alt-click inserts it after the target instead (`jj rebase -r -A`). Cancel in the dock stops the move |
| Fetch or undo | The Fetch and Undo buttons in the dock |

The tree refreshes every 2 seconds, so commands you run in a shell and files you edit show up on their own. Immutable changes have the actions that would rewrite them turned off.

## Notes

- Describe… and Split… need an editor, so they open a terminal below the block. The terminal closes when jj finishes.
- Squash keeps the parent's description (`--use-destination-message`), because jj cannot combine two descriptions without an editor.
- A failed command shows a toast with jj's error. Other commands never wait for an editor: they run with `JJ_EDITOR=false`.
- Diffs larger than 200 KB are cut.
- The diff block opens through a link that `window.luau` routes, so the plugin must be installed in the window too (`tern plugin list` shows `window`).
