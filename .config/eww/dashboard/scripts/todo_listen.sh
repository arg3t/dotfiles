#!/usr/bin/env bash

FILE_TODO="$HOME/Documents/todo.txt"

mkdir -p "$(dirname "$FILE_TODO")"
touch "$FILE_TODO"

generate_json() {
  line1=$(sed -n '1p' "$FILE_TODO" | sed 's/"/\\"/g')
  line2=$(sed -n '2p' "$FILE_TODO" | sed 's/"/\\"/g')
  line3=$(sed -n '3p' "$FILE_TODO" | sed 's/"/\\"/g')

  echo "{\"line1\":\"$line1\", \"line2\":\"$line2\", \"line3\":\"$(sed -n '3p' "$FILE_TODO" | sed 's/"/\\"/g')\"}"
}

generate_json

while inotifywait -e close_write "$FILE_TODO" >/dev/null 2>&1; do
  generate_json
done
