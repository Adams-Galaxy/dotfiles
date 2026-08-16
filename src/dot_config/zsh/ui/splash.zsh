# Optional terminal splash.

# Environments to skip the splash in. Each entry is either "VAR" (skip
# whenever $VAR is non-empty, e.g. tmux setting $TMUX) or "VAR=value"
# (skip only on an exact match, e.g. VS Code's integrated terminal).
SPLASH_SKIP_IN=(
  "TERM_PROGRAM=vscode"
  "TMUX"
  "NVIM"
)

# Below this, fastfetch's side-by-side logo+info layout wraps or truncates
# rather than looking right.
: ${SPLASH_MIN_COLUMNS:=80}

# Height brackets: "min_lines:config_path" pairs, tallest first. splash()
# picks the first one $LINES clears. config.jsonc groups modules into
# Hardware/Software/Desktop/Extras boxes (~30 lines); config-compact.jsonc
# is the same modules/icons/colors flattened into a single box (~21 lines)
# for shorter terminals where the extra headers/borders would just eat
# into scroll history. The last bracket's min_lines doubles as the overall
# floor below which the splash is skipped entirely.
SPLASH_HEIGHT_BRACKETS=(
  "34:${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc"
  "22:${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config-compact.jsonc"
)

# If the splash should be skipped, return 0. Otherwise return 1.
splash_should_skip() {
  # If the splash has already been shown in this shell, skip it.
  if [[ -n "${ZSHRC_RELOADED:-}" ]]; then
    return 0
  fi

  # If the terminal is too small, skip it. The floor is the shortest
  # bracket's min_lines — anything under that has no config to fall back to.
  local floor_lines="${SPLASH_HEIGHT_BRACKETS[-1]%%:*}"
  if (( COLUMNS < SPLASH_MIN_COLUMNS || LINES < floor_lines )); then
    return 0
  fi

  # If any of the SPLASH_SKIP_IN conditions are met, skip it.
  local entry var value
  for entry in "${SPLASH_SKIP_IN[@]}"; do
    var="${entry%%=*}"
    if [[ "$entry" == *=* ]]; then
      value="${entry#*=}"
      [[ "${(P)var}" == "$value" ]] && return 0
    else
      [[ -n "${(P)var}" ]] && return 0
    fi
  done
  return 1
}

splash() {
  if ! command -v fastfetch >/dev/null 2>&1; then
    print "fastfetch is not installed"
    return 1
  fi

  local entry min_lines config_path chosen=""
  for entry in "${SPLASH_HEIGHT_BRACKETS[@]}"; do
    min_lines="${entry%%:*}"
    config_path="${entry#*:}"
    if (( LINES >= min_lines )); then
      chosen="$config_path"
      break
    fi
  done

  # Gap between the big logo (icon.txt) and the module column — fastfetch's
  # --logo-padding-right, overriding the "padding.right": 2 baked into both
  # config files. Computing it fresh from $COLUMNS on every render (a
  # resize takes effect on the next prompt) means this doesn't need yet
  # more static config variants alongside the height brackets above.
  #
  # 16 (the original static value) is the ideal, held constant above
  # SPLASH_LOGO_PADDING_COMFORTABLE_COLUMNS rather than growing further —
  # this is a gap, not a layout that should keep spreading out on an
  # ultrawide. Below that it interpolates down to 0 at $SPLASH_MIN_COLUMNS,
  # so it only compresses to fit a cramped terminal instead of the reverse.
  : ${SPLASH_LOGO_PADDING_MIN:=0}
  : ${SPLASH_LOGO_PADDING_IDEAL:=16}
  : ${SPLASH_LOGO_PADDING_COMFORTABLE_COLUMNS:=120}

  local logo_padding=$(( SPLASH_LOGO_PADDING_MIN + (SPLASH_LOGO_PADDING_IDEAL - SPLASH_LOGO_PADDING_MIN)
    * (COLUMNS - SPLASH_MIN_COLUMNS)
    / (SPLASH_LOGO_PADDING_COMFORTABLE_COLUMNS - SPLASH_MIN_COLUMNS) ))
  (( logo_padding > SPLASH_LOGO_PADDING_IDEAL )) && logo_padding=$SPLASH_LOGO_PADDING_IDEAL
  (( logo_padding < SPLASH_LOGO_PADDING_MIN )) && logo_padding=$SPLASH_LOGO_PADDING_MIN

  if [[ -n "$chosen" ]]; then
    fastfetch -c "$chosen" --logo-padding-right "$logo_padding"
  else
    fastfetch --logo-padding-right "$logo_padding"
  fi
}
