#!/usr/bin/env bash

get_status() {
  audio_output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
  if echo "$audio_output" | grep -q "MUTED"; then
    audio="muted"
  else
    audio="unmuted"
  fi

  mic_output=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)
  if echo "$mic_output" | grep -q "MUTED"; then
    mic="muted"
  else
    mic="unmuted"
  fi

  printf '{"audio": "%s", "mic": "%s"}\n' "$audio" "$mic"
}

get_status

pactl subscribe | stdbuf -oL grep --line-buffered "change" | while read -r _; do
  get_status
done
