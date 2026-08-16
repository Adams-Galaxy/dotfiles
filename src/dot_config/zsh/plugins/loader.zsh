# Antidote bundle loading with manifest-change invalidation.

load_zsh_plugin_bundle() {
  local manifest="$1" bundle="$2" antidote_zsh candidate

  [[ -f "$manifest" ]] || return 0

  if [[ ! -f "$bundle" || "$manifest" -nt "$bundle" ]]; then
    for candidate in \
      "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" \
      /opt/homebrew/opt/antidote/share/antidote/antidote.zsh \
      /usr/local/opt/antidote/share/antidote/antidote.zsh \
      "$HOME/.antidote/antidote.zsh"; do
      [[ -f "$candidate" ]] && { antidote_zsh="$candidate"; break }
    done

    if [[ -n "$antidote_zsh" ]]; then
      [[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
      source "$antidote_zsh"
      antidote bundle < "$manifest" > "$bundle"
    fi
  fi

  [[ -f "$bundle" ]] && source "$bundle"
}
