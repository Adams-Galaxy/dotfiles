# Dynamic completions emitted by external tools.
#
# This runs after compinit so generated functions can register against the
# initialized completion system while static completion policy stays separate.

if (( ${+commands[wombat]} )); then
  cache_init wombat wombat completions zsh
fi
