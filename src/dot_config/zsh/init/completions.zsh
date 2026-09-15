# Dynamic completions emitted by external tools.
#
# This runs after compinit so generated functions can register against the
# initialized completion system while static completion policy stays separate.

if has_command wombat; then
  cache_init wombat wombat completions zsh
fi

if has_command tailscale; then
  cache_init tailscale tailscale completion zsh
fi
