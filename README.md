# Dotfiles

Mid-migration. This repo used to be managed by `chezmoi`, with `tinty`
(tinted-theming) layered on top for shared color theming. Both have been
removed: no more chezmoi control files (`.chezmoi*`), no more `run_once_*`
hooks, no more tinty config or generated theme data.

What's left under `dot_config/`, `dot_tmux.conf`, `dot_zshrc`, etc. is real,
working configuration content - previously templated files (starship,
fastfetch, wezterm, tmux, common.zsh) have been frozen to their last-applied
literal values, so nothing changed on disk. `scripts/packages.conf` is still
the real package inventory.

This is being rebuilt around [Wombat](https://github.com/Adams-Galaxy/wombat),
a Lua-powered dotfiles compiler, on the `wombat-migration` branch. The new
structure - module layout, theming design, package/requirement declarations -
is being designed fresh rather than carried over from the chezmoi shape.
Until that lands, this README stays a placeholder.
