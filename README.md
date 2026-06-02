# Dotfiles

This repository is a `chezmoi`-managed dotfiles setup for macOS and Linux.

## What chezmoi does here

`chezmoi` keeps your dotfiles in two places:

- the **source tree** in this repository
- the **target tree** in your home directory

So a file such as `dot_config/zsh/dot_zshrc` becomes `~/.config/zsh/.zshrc` after `chezmoi init --apply` or `chezmoi apply`.

Template files are only used when a file needs machine-specific data. Everything else stays as plain shell or config files, which keeps the repo easier to read and less magical than it strictly needs to be.

## What this repo manages

- `dot_config/` — managed configuration for Zsh, Git, Starship, and related tools
- `dot_config/yazi/` — Yazi configuration and theme files
- `run_once_*.sh.tmpl` — one-time bootstrap steps that run after apply
- `scripts/` — repo-local helper scripts and package manifests used during setup
- `docs/` — notes and migration docs

## Fresh machine setup

On a new Mac or Linux machine, the goal is:

1. Install `chezmoi`.
2. Run `chezmoi init --apply Adams-Galaxy`.
3. Let the run-once bootstrap finish the rest:
   - create runtime directories used by Zsh
   - install Homebrew automatically on macOS if needed
   - install Oh My Zsh and the custom plugins
   - install the shell tools and completions
4. Open a new shell.

## Bootstrap behavior

The bootstrap path is designed to be reusable and predictable:

- `run_once_before_setup_bootstrap.sh.tmpl` handles first-run setup after chezmoi applies
- `scripts/bootstrap.sh` can be rerun later with `--install-only` if you only want dependency setup
- `scripts/packages.sh` is the single place to extend the default shell/tool install list
- macOS and Linux are both supported
- missing tools are installed as part of the setup instead of being assumed

## Zsh layout

The Zsh config is split into small focused pieces:

- `env/common.zsh` — shared environment variables
- `env/path.zsh` — PATH handling
- `env/completion.zsh` — completion setup
- `env/functions.zsh` — shell functions
- `env/aliases.zsh` — aliases and editor helpers
- `env/prompt.zsh` — Starship, zoxide, atuin, and direnv startup
- `env/plugins.zsh` — Oh My Zsh plugin loading
- `os/macos.zsh` and `os/linux.zsh` — OS-specific behavior
- `local/local.zsh.tmpl` — private machine overrides

## Notes

- The old standalone `zsh/` tree has been replaced by `dot_config/zsh/`.
- If you want to rerun only the dependency setup later, use `scripts/bootstrap.sh --install-only` from the source tree.
