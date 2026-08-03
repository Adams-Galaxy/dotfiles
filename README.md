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
