# External tools that attach shell behavior during startup.

if has_command starship; then
  cache_init starship starship init zsh
fi

if has_command zoxide; then
  cache_init zoxide zoxide init --cmd cd zsh
  # Zoxide owns cd, so retain z as its conventional explicit entry point.
  alias z="cd"
fi

if has_command atuin; then
  cache_init atuin atuin init zsh
fi

if has_command direnv; then
  cache_init direnv direnv hook zsh
fi

if has_command burrow; then
  cache_init burrow burrow init zsh
  alias b="burrow"
fi
