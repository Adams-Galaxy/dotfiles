# Optional splash helper

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
: ${SPLASH_MIN_LINES:=24}

splash_should_skip() {
  if [[ -n "${ZSHRC_RELOADED:-}" ]]; then
    return 0
  fi

  if (( COLUMNS < SPLASH_MIN_COLUMNS || LINES < SPLASH_MIN_LINES )); then
    return 0
  fi

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
  if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
  else
    print "fastfetch is not installed"
  fi
}
