# Project-specific loading

autoload -U add-zsh-hook

load_project_config() {
  local project_file=".project.zsh"

  if [[ -f "$PWD/$project_file" ]]; then
    source "$PWD/$project_file"
  fi
}

add-zsh-hook chpwd load_project_config
load_project_config
