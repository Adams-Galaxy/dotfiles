# General command shorthand and portable command names.

clear() {
  command clear
  printf '\e[3J'
}

alias c="clear"
alias q="exit"

if has_command rg; then
  alias grep="rg"
fi

if has_command eza; then
  alias ls="eza"
  alias la="eza -la"
else
  alias ls="ls"
  alias la="ls -la"
fi

if ! has_command fd && has_command fdfind; then
  alias fd="fdfind"
fi

if ! has_command bat && has_command batcat; then
  alias bat="batcat"
fi
