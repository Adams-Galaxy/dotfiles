# Terminal and GUI editor workflows.

edit() {
  if has_command "$SHELL_EDITOR"; then
    "$SHELL_EDITOR" "$@"
  elif has_command nvim; then
    nvim "$@"
  elif has_command vim; then
    vim "$@"
  else
    print -u2 "No terminal editor found"
    return 127
  fi
}

sudoedit() {
  if ! has_command sudo; then
    print -u2 "sudo is not available"
    return 127
  fi

  if has_command "$SHELL_EDITOR"; then
    sudo "$SHELL_EDITOR" "$@"
  elif has_command nvim; then
    sudo nvim "$@"
  elif has_command vim; then
    sudo vim "$@"
  else
    print -u2 "No terminal editor found"
    return 127
  fi
}

gui_edit() {
  if has_command "$GUI_EDITOR"; then
    "$GUI_EDITOR" "$@"
  else
    edit "$@"
  fi
}

v() { gui_edit . }
e() { edit "$@" }
se() { sudoedit "$@" }
hosts() { sudoedit /etc/hosts }
