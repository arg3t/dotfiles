#!/bin/sh
tmpfile=$(mktemp $XDG_RUNTIME_DIR/st-edit.XXXXXX)
trap  'rm "$tmpfile"' 0 1 15
cat > "$tmpfile"
st -e "$EDITOR" "$tmpfile"
