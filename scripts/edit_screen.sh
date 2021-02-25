#!/bin/sh
tmpfile=$(mktemp /tmp/st-edit.XXXXXX)
trap  'rm "$tmpfile"' 0 1 15
cat > "$tmpfile"
st -e "$EDITOR" "$tmpfile"
