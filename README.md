# Dotfiles

This repository is being rebuilt around `chezmoi`.

## Goals

- portable across macOS and Linux
- small, composable config files
- machine-specific values kept private
- one-command bootstrap for new machines

## Current direction

- `chezmoi` manages the source of truth
- Zsh config is split into shared, OS-specific, and local layers
- bootstrap scripts install dependencies and shell tooling

## Layout

- `dot_config/` contains chezmoi-managed configuration
- `docs/` contains migration notes and design docs
- `scripts/` contains repo-local helper scripts and is ignored by chezmoi
- the old `zsh/` tree has been removed in favor of `dot_config/zsh/`

See `docs/chezmoi-migration.md` for the migration plan.
