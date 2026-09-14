# Wombat's everyday inspection and delivery commands. `w` is reserved for the
# existing Zsh command, so these stay compact without shadowing it.
if has_command wombat; then
  alias wb="wombat build"
  alias wp="wombat plan"
  alias wa="wombat apply"
  alias wd="wombat diff"
  alias wi="wombat inspect"
  alias we="wombat explain"
  alias wc="wombat check"
fi
