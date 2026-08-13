# Prompt and shell tool startup
#
# Each of these ships its shell integration via `<tool> init zsh`, which
# means a subprocess per tool on every startup. cache_init (common.zsh)
# stores the generated code and re-runs the tool only when its binary
# changes, so the steady-state cost is a plain source.

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

# Completions
if (( ${+commands[wombat]} )); then
  cache_init wombat completions zsh
fi