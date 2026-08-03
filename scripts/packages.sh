# Package manifest for shell bootstrap.
# Add or remove tools here to extend the default install.

MACOS_PACKAGES="git curl zsh starship zoxide atuin direnv eza neovim yazi fastfetch fzf fd ripgrep bat gh git-delta lazygit lazydocker btop tmux"

LINUX_BASE_PACKAGES="git zsh bash curl ca-certificates"
LINUX_TOOL_PACKAGES="zoxide atuin direnv eza neovim yazi fastfetch fzf fd ripgrep bat gh lazygit lazydocker btop tmux"

APT_EXTRA_PACKAGES="delta"
DNF_EXTRA_PACKAGES="delta"
PACMAN_EXTRA_PACKAGES="git-delta"
ZYPPER_EXTRA_PACKAGES="git-delta"
APK_EXTRA_PACKAGES="git-delta"

OMZ_PLUGINS="zsh-autosuggestions zsh-syntax-highlighting zsh-completions"
