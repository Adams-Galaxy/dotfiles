#!/bin/sh

# Bring this dotfiles repository onto a new machine, then make the shell it
# deploys the account's login shell. Wombat itself cannot make that choice:
# another repository may deliberately configure a different shell.
set -eu

repository=${DOTFILES_REPOSITORY:-"Adams-Galaxy/dotfiles"}
wombat_installer=${WOMBAT_INSTALLER_URL:-"https://raw.githubusercontent.com/Adams-Galaxy/wombat/main/install.sh"}

have() {
    command -v "$1" >/dev/null 2>&1
}

if ! have curl; then
    printf '%s\n' "curl is required to install Wombat." >&2
    exit 1
fi

# This is intentionally a fresh-machine entry point, so the prerequisite layer
# is explicitly authorized before Wombat compiles itself and brings up this
# repository. Project arguments (for example -- --machine=bob) pass through.
installer=$(mktemp "${TMPDIR:-/tmp}/dotfiles-wombat-installer.XXXXXX")
trap 'rm -f "$installer"' EXIT HUP INT TERM
curl -fsSL "$wombat_installer" -o "$installer"
sh "$installer" --install-prerequisites setup "$repository" "$@"

if ! have zsh; then
    printf '%s\n' "Wombat setup completed, but Zsh was not installed; refusing to change the login shell." >&2
    exit 1
fi

zsh_path=$(command -v zsh)
case "$(uname -s)" in
    Darwin)
        current_shell=$(dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{ print $2 }')
        ;;
    *)
        current_shell=$(getent passwd "$(id -un)" 2>/dev/null | awk -F: '{ print $7 }')
        ;;
esac

if [ "$current_shell" = "$zsh_path" ]; then
    printf '%s\n' "Zsh is already the login shell ($zsh_path)." >&2
    exit 0
fi

# chsh authenticates the account owner. It must use a real terminal rather
# than Wombat's captured script runner, so a one-line curl installation can
# safely request the password without broadening account mutation privileges.
if [ ! -r /dev/tty ]; then
    printf '%s\n' "Wombat setup completed, but changing the login shell needs a terminal. Run: chsh -s $zsh_path" >&2
    exit 1
fi

printf '%s\n' "Setting the login shell to $zsh_path (your account password may be required)." >&2
chsh -s "$zsh_path" < /dev/tty
printf '%s\n' "Zsh is now the login shell. Open a new terminal session to use it." >&2
