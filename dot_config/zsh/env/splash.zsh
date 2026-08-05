# Optional splash helper

# Environments to skip the splash in. Each entry is either "VAR" (skip
# whenever $VAR is non-empty, e.g. tmux setting $TMUX) or "VAR=value"
# (skip only on an exact match, e.g. VS Code's integrated terminal).
SPLASH_SKIP_IN=(
  "TERM_PROGRAM=vscode"
  "TMUX"
  "NVIM"
)

splash_should_skip() {
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
