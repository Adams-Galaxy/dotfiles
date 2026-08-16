# Small, side-effect-free command aliases.

clear() {
  command clear
  printf '\e[3J'
}

alias c="clear"
alias q="exit"

if command -v rg >/dev/null 2>&1; then
  alias grep="rg"
fi

if command -v eza >/dev/null 2>&1; then
  alias ls="eza"
  alias la="eza -la"
else
  alias ls="ls"
  alias la="ls -la"
fi

if command -v lazygit >/dev/null 2>&1; then
  alias lg="lazygit"
fi

if command -v tmux >/dev/null 2>&1; then
  alias tm="tmux"
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd="fdfind"
fi

if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat="batcat"
fi

# Git aliases
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"
alias gd="git diff"
alias gds="git diff --staged"
alias gb="git branch"
alias gco="git checkout"
alias gsw="git switch"

# Zsh reload alias
alias zr="source ~/.zshrc"
alias zrst="clear && printf '\e[3J' && exec zsh -l"

# Because zoxide --cmd is set to "cd", so we preserve "z" for still function as default z
alias z="cd"

alias ff="splash"
alias cff="clear && splash"

# Burrow
alias b="burrow"
