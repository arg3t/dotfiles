#!/usr/bin/env bash

THEME_DIR="$HOME/.config/eww/theme"
TOKENS="$THEME_DIR/tokens.scss"
CURRENT_THEME_FILE="$THEME_DIR/current_theme_state"

TARGET_THEME=$1

CURRENT_THEME=$(cat "$CURRENT_THEME_FILE" 2>/dev/null)

# safety
if [[ "$TARGET_THEME" == "catppuccin_mocha" && "$CURRENT_THEME" == "catppuccin mocha" ]]; then
  exit 0
fi

if [[ "$TARGET_THEME" == "catppuccin_latte" && "$CURRENT_THEME" == "catppuccin latte" ]]; then
  exit 0
fi

if [[ "$TARGET_THEME" == "tokyo_night" && "$CURRENT_THEME" == "tokyo night" ]]; then
  exit 0
fi

if [[ "$TARGET_THEME" == "tokyo_night_light" && "$CURRENT_THEME" == "tokyo night light" ]]; then
  exit 0
fi

if [ "$TARGET_THEME" = "catppuccin_mocha" ]; then
  cp "$THEME_DIR/catppuccin_mocha.scss" "$TOKENS"

  echo "catppuccin mocha" >"$CURRENT_THEME_FILE"

  notify-send -u low \
    -i "preferences-theme" \
    "Theme Switcher" \
    "Changed to Catppuccin Mocha"

elif [ "$TARGET_THEME" = "catppuccin_latte" ]; then
  cp "$THEME_DIR/catppuccin_latte.scss" "$TOKENS"

  echo "catppuccin latte" >"$CURRENT_THEME_FILE"

  notify-send -u low \
    -i "preferences-theme" \
    "Theme Switcher" \
    "Changed to Catppuccin Latte"

elif [ "$TARGET_THEME" = "tokyo_night" ]; then
  cp "$THEME_DIR/tokyo_night.scss" "$TOKENS"

  echo "tokyo night" >"$CURRENT_THEME_FILE"

  notify-send -u low \
    -i "preferences-theme" \
    "Theme Switcher" \
    "Changed to Tokyo Night"

elif [ "$TARGET_THEME" = "tokyo_night_light" ]; then
  cp "$THEME_DIR/tokyo_night_light.scss" "$TOKENS"

  echo "tokyo night light" >"$CURRENT_THEME_FILE"

  notify-send -u low \
    -i "preferences-theme" \
    "Theme Switcher" \
    "Changed to Tokyo Night Light"
fi
