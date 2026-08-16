# Wombat source-repository workflows.

# Open the dotfiles source directory in yazi, for browsing/file-ops
dotfiles() { y "$WOMBAT_SOURCE_DIR" }

# cd into the dotfiles source directory
dotcd() { cd "$WOMBAT_SOURCE_DIR" }

# Open the dotfiles source directory as a Neovim project
dotedit() { "${EDITOR:-nvim}" "$WOMBAT_SOURCE_DIR" }

# Fuzzy-edit a single file within the dotfiles source directory
dfe() {
  local file

  file="$(
    fd \
      --type f \
      --hidden \
      --follow \
      --exclude .git \
      . "$WOMBAT_SOURCE_DIR" |
    fzf \
      --prompt='dotfiles> ' \
      --preview='bat --color=always --style=numbers --line-range=:500 {}'
  )" || return

  "${EDITOR:-nvim}" "$file"
}
