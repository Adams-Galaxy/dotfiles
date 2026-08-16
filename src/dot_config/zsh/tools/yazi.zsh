# Yazi wrappers that preserve the directory selected by the file manager.

y() {
  local tmp
  local cwd

  if ! command -v yazi >/dev/null 2>&1; then
    if [[ $# -gt 0 && -d "$1" ]]; then
      builtin cd -- "$1"
      return 0
    fi

    print -u2 "yazi is not installed"
    return 127
  fi

  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  if [[ "$cwd" != "$PWD" && -d "$cwd" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

sy() {
  local tmp
  local cwd

  if ! command -v yazi >/dev/null 2>&1; then
    if [[ $# -gt 0 && -d "$1" ]]; then
      builtin cd -- "$1"
      return 0
    fi

    print -u2 "yazi is not installed"
    return 127
  fi

  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  sudo -E yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  if [[ "$cwd" != "$PWD" && -d "$cwd" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
