# Common aliases

alias cls="clear"
alias c="clear"
alias q="exit"

alias ls="eza"
alias la="eza -la"

alias v="code ."

alias p="python"
alias dv="source ~/dev/.venv/bin/activate"

alias hosts="sudo nvim /etc/hosts"
alias song="mufetch search"

alias splosh="$DOTFILES/scripts/colortest.sh"
alias splesh="splash && $DOTFILES/scripts/colortest.sh"

alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

alias aliases="nvim $DOTFILES/env/aliases.zsh"
alias valiases="code $DOTFILES/env/aliases.zsh"
alias macros="nvim $DOTFILES/env/functions.zsh"
alias vmacros="code $DOTFILES/env/functions.zsh"

alias zshcfg="nvim ~/.zshrc"
alias vzshcfg="code ~/.zshrc"
alias zshrld="source ~/.zshrc"
alias rld="source ~/.zshrc"

alias sshkeys="nvim ~/.ssh/authorized_keys"
