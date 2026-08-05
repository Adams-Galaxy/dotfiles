# Dotfiles

`chezmoi`-managed dotfiles setup for my macOS and Linux development environments.

## Fresh machine setup because I will forget everything otherwise

1. Install `chezmoi`.
2. Run `chezmoi init --apply Adams-Galaxy`.
3. Let the run-once bootstrap finish the rest:
   - create runtime directories used by Zsh
   - install zsh and make it the login shell on Linux when needed
   - install Homebrew automatically on macOS if needed
   - install Oh My Zsh and the custom plugins
   - install Yazi via distro packages, with an official GitHub `.deb` fallback on apt-based Linux when package repos don't provide it
   - install tmux, TPM, and the configured tmux plugins
   - install the shell tools and completions
4. Open a new shell.

## Day-to-day workflow

A handful of zsh functions (`dot_config/zsh/env/chezmoi.zsh`) make editing
this repo from anywhere less annoying:

| Command | Does |
| --- | --- |
| `dotcd` | `cd` into the dotfiles source directory |
| `dotedit` | Open the source directory as a Neovim/LazyVim project |
| `dfe` | Fuzzy-find and open a single file within the source directory |
| `dotfiles` | Browse the source directory in yazi |
| `dotdiff` | `chezmoi diff` |
| `dotstatus` | `chezmoi status` |
| `dotapply` | `chezmoi apply`, then reloads the current shell and tmux (if running) |

Inside Neovim, the same diff/apply/status actions are under `<leader>m`
(`lua/plugins/chezmoi.lua`).

Before applying, run `scripts/check.sh` — it syntax-checks every shell/zsh
script (rendering `.tmpl` files with `chezmoi execute-template` first),
`luac -p`s the Neovim Lua config, validates TOML/JSON files, checks
`scripts/packages.conf`'s shape, and does a full `chezmoi apply --dry-run`
to catch template errors before they hit `$HOME`.

## Packages

`scripts/packages.conf` is the single source of truth for what gets
installed by `scripts/bootstrap.sh` — one row per package, tagged with the
OS(es) and (optionally) the profile it applies to. Edit it with `dotpkg`
rather than by hand:

```sh
dotpkg add <name> --profiles=macos,linux [--apt=name] [--dnf=name] [--pacman=name] [--zypper=name] [--apk=name] [--brew=name]
dotpkg remove <name>
dotpkg list
```

A package with no profile tag (just `macos`/`linux`) installs under every
profile; add a profile tag only to restrict it (e.g. `macos,linux,work`).

## Profiles

`chezmoi init` prompts for a `profile` (default `personal`), stored in
`~/.config/chezmoi/chezmoi.toml` and available to templates as `.profile`.
`scripts/bootstrap.sh` resolves the same value from the `DOTFILES_PROFILE`
env var (also defaulting to `personal`) and feeds it to both the package
manifest filter and the `chezmoi init` prompt, so the two can't disagree:

```sh
DOTFILES_PROFILE=work sh scripts/bootstrap.sh <repo-url>
```

Gate a dotfile on the profile with `{{ if eq .profile "work" }}` inside a
`.tmpl` file or `.chezmoiignore`.
