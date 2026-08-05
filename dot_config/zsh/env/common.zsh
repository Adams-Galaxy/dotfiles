# Shared environment

export EDITOR="nvim"
export VISUAL="nvim"
export SHELL_EDITOR="nvim"
export GUI_EDITOR="code"
export PAGER="less"
export LANG="en_US.UTF-8"
export SCRIPTS="$DOTFILES/scripts"

export CHEZMOI_SOURCE_DIR="$HOME/.local/share/chezmoi"
export CHEZMOI_DOT_CONFIG_DIR="$CHEZMOI_SOURCE_DIR/dot_config"
export CHEZMOI_ZSH_DIR="$CHEZMOI_DOT_CONFIG_DIR/zsh"
export CHEZMOI_ZSH_ENV_DIR="$CHEZMOI_ZSH_DIR/env"

# Gruvbox Dark, matching the palette in starship.toml
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height 40% --layout=reverse --border \
--color=fg:#ebdbb2,fg+:#fbf1c7,bg+:#3c3836 \
--color=hl:#83a598,hl+:#fe8019 \
--color=info:#8ec07c,marker:#fe8019 \
--color=prompt:#fabd2f,spinner:#fabd2f \
--color=pointer:#fabd2f,header:#83a598 \
--color=border:#665c54,label:#ebdbb2}"

export HOME_SSID="SurveillanceVan2"
