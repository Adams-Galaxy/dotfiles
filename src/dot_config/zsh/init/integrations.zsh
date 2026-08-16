# External tools that attach shell behavior during startup.

if (( ${+commands[starship]} )); then
  cache_init starship starship init zsh
fi

if (( ${+commands[zoxide]} )); then
  cache_init zoxide zoxide init --cmd cd zsh
fi

if (( ${+commands[atuin]} )); then
  cache_init atuin atuin init zsh
fi

if (( ${+commands[direnv]} )); then
  cache_init direnv direnv hook zsh
fi

if (( ${+commands[burrow]} )); then
  cache_init burrow burrow init zsh
fi
