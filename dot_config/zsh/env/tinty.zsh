# tinty (tinted-theming CLI) shell integration.
#
# Colors for the tools with an official tinted-theming template, no
# chezmoi template of their own, AND an [[items]] entry in
# dot_config/tinted-theming/tinty/config.toml.tmpl (currently just
# tinted-shell's ANSI/$BASE16_* exports, and tinted-yazi's flavor file)
# come from files tinty writes to its data dir, not from chezmoi. Those
# files need
# sourcing into every new shell, and — per tinty's own docs — a plain
# `tinty apply` can't do that itself: "Tinty isn't able to apply
# environment variables to your shell due to the way shell sub-processes
# work." This wrapper is tinty's own recommended snippet (not
# hand-rolled) — works around it by re-sourcing whatever the command just
# touched, in the CURRENT shell, right after it runs. One fix versus the
# upstream version: their `find` uses a bare `-type f -o -type l -name
# "*.sh" -newer ...` without grouping, so operator precedence makes any
# plain file match unconditionally (the -name/-newer filters only bind to
# the -type l branch) — verified this actually happens against a live
# tinty data dir (it matched .tinty.lock and current_scheme too, both
# non-.sh files). Explicit `\( -type f -o -type l \)` grouping below fixes
# that. Second fix: upstream calls the bare `tinty` inside this function's
# own body, but the last line below aliases `tinty` to this same function
# — so re-sourcing this file (`zr`/`crr` in aliases.zsh do exactly that)
# redefines the function while the alias from the FIRST sourcing is still
# live, and the bare call inside the new body alias-expands to itself:
# infinite recursion ("maximum nested function level reached"), verified
# by re-sourcing this file twice in one shell. `command tinty` forces the
# real binary regardless of what `tinty` is currently aliased to.
if command -v tinty >/dev/null 2>&1; then
  tinty_source_shell_theme() {
    local newer_file
    newer_file=$(mktemp)
    command tinty "$@"
    local subcommand="$1"

    if [[ "$subcommand" == "apply" || "$subcommand" == "init" ]]; then
      local tinty_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
      local script

      while read -r script; do
        source "$script"
      done < <(find "$tinty_data_dir" -maxdepth 1 \( -type f -o -type l \) -name "*.sh" -newer "$newer_file")

      unset tinty_data_dir
    fi

    rm -f "$newer_file"
    unset subcommand newer_file
  }

  tinty_source_shell_theme "init" > /dev/null

  alias tinty=tinty_source_shell_theme
fi
