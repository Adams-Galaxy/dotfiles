# Small, dependency-free helpers shared by the rest of the Zsh configuration.

# Return success when an external command is available on PATH. The `commands`
# parameter is maintained by Zsh and avoids spawning a command lookup process.
has_command() {
  (( ${+commands[$1]} ))
}

# Source direct, regular .zsh files from a configuration directory in Zsh's
# stable lexical glob order. Empty directories are valid, and recursion is
# deliberately excluded so load order stays obvious from the directory listing.
source_zsh_directory() {
  emulate -L zsh
  setopt null_glob

  local directory="$1"
  local file
  for file in "$directory"/*.zsh(.N); do
    source "$file" || return
  done
}
