# Dotfiles (chezmoi) workflow helpers

# Open the dotfiles source directory in yazi, for browsing/file-ops
dotfiles() {
  y "$CHEZMOI_SOURCE_DIR"
}

# cd into the dotfiles source directory
dotcd() {
  cd "$CHEZMOI_SOURCE_DIR"
}

# Open the dotfiles source directory as a Neovim project
dotedit() {
  "${EDITOR:-nvim}" "$CHEZMOI_SOURCE_DIR"
}

# Fuzzy-edit a single file within the dotfiles source directory
dfe() {
  local file

  file="$(
    fd \
      --type f \
      --hidden \
      --follow \
      --exclude .git \
      . "$CHEZMOI_SOURCE_DIR" |
    fzf \
      --prompt='dotfiles> ' \
      --preview='bat --color=always --style=numbers --line-range=:500 {}'
  )" || return

  "${EDITOR:-nvim}" "$file"
}

# Show what chezmoi would change on the next apply
dotdiff() {
  chezmoi diff "$@"
}

# Show managed/unmanaged file status
dotstatus() {
  chezmoi status "$@"
}

# Apply chezmoi changes, then reload the current shell (and tmux, if running)
dotapply() {
  chezmoi apply "$@" || return 1

  source "$HOME/.zshrc"

  if [[ -n "$TMUX" ]]; then
    tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1
  fi
}

