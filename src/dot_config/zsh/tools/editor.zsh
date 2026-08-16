# Terminal and GUI editor workflows.

edit() {
  if command -v "$SHELL_EDITOR" >/dev/null 2>&1; then
    "$SHELL_EDITOR" "$@"
  elif command -v nvim >/dev/null 2>&1; then
    nvim "$@"
  elif command -v vim >/dev/null 2>&1; then
    vim "$@"
  else
    print -u2 "No terminal editor found"
    return 127
  fi
}

sudoedit() {
  if ! command -v sudo >/dev/null 2>&1; then
    print -u2 "sudo is not available"
    return 127
  fi

  if command -v "$SHELL_EDITOR" >/dev/null 2>&1; then
    sudo "$SHELL_EDITOR" "$@"
  elif command -v nvim >/dev/null 2>&1; then
    sudo nvim "$@"
  elif command -v vim >/dev/null 2>&1; then
    sudo vim "$@"
  else
    print -u2 "No terminal editor found"
    return 127
  fi
}

gui_edit() {
  if command -v "$GUI_EDITOR" >/dev/null 2>&1; then
    "$GUI_EDITOR" "$@"
  else
    edit "$@"
  fi
}

v() { gui_edit . }
e() { edit "$@" }
se() { sudoedit "$@" }
hosts() { sudoedit /etc/hosts }
