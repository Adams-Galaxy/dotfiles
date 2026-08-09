# Common aliases

alias c="clear && printf '\e[3J'"
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

edit() {
  if command -v "$SHELL_EDITOR" >/dev/null 2>&1; then
    "$SHELL_EDITOR" "$@"
  elif command -v nvim >/dev/null 2>&1; then
    nvim "$@"
  elif command -v vim >/dev/null 2>&1; then
    vim "$@"
  else
    print "No terminal editor found"
    return 127
  fi
}

sudoedit() {
  if command -v sudo >/dev/null 2>&1; then
    if command -v "$SHELL_EDITOR" >/dev/null 2>&1; then
      sudo "$SHELL_EDITOR" "$@"
    elif command -v nvim >/dev/null 2>&1; then
      sudo nvim "$@"
    elif command -v vim >/dev/null 2>&1; then
      sudo vim "$@"
    else
      print "No terminal editor found"
      return 127
    fi
  else
    print "sudo is not available"
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

v() {
  gui_edit .
}

e() {
  edit "$@"
}

se() {
  sudoedit "$@"
}

# Python aliases
alias p="python3"

hosts() {
  sudoedit /etc/hosts
}

song() {
  if command -v mufetch >/dev/null 2>&1; then
    mufetch search "$@"
  else
    print "mufetch is not installed"
    return 127
  fi
}

splosh() {
  "$DOTFILES/scripts/colortest.sh"
}

splesh() {
  splash && "$DOTFILES/scripts/colortest.sh"
}

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

