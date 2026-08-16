# Cached generated shell integrations.
#
# Tool-provided `init zsh` output is re-generated only after its executable
# changes, keeping normal startup to a source rather than a subprocess.

cache_init() {
  local name="$1"; shift
  local cache="$ZSH_CACHE_DIR/init-$name.zsh"

  if [[ ! -f "$cache" || "${commands[$1]}" -nt "$cache" ]]; then
    [[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
    "$@" > "$cache" 2>/dev/null || { rm -f "$cache"; return 1 }
  fi

  source "$cache"
}
