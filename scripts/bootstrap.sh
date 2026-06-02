#!/usr/bin/env sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
repo_url="${CHEZMOI_REPO_URL:-${1:-}}"
install_only=0
packages_file="$repo_dir/scripts/packages.sh"

if [ -f "$packages_file" ]; then
  . "$packages_file"
fi

: "${MACOS_PACKAGES:=git curl zsh starship zoxide atuin direnv eza neovim yazi fastfetch fzf fd ripgrep bat gh git-delta lazygit lazydocker btop}"
: "${LINUX_BASE_PACKAGES:=git zsh curl ca-certificates}"
: "${LINUX_TOOL_PACKAGES:=zoxide atuin direnv eza neovim yazi fastfetch fzf fd ripgrep bat gh lazygit lazydocker btop}"
: "${APT_EXTRA_PACKAGES:=delta}"
: "${DNF_EXTRA_PACKAGES:=delta}"
: "${PACMAN_EXTRA_PACKAGES:=git-delta}"
: "${ZYPPER_EXTRA_PACKAGES:=git-delta}"
: "${APK_EXTRA_PACKAGES:=git-delta}"
: "${OMZ_PLUGINS:=zsh-autosuggestions zsh-syntax-highlighting zsh-completions}"

if [ "${1:-}" = "--install-only" ]; then
  install_only=1
  repo_url=""
fi

if [ "$install_only" -eq 0 ]; then
  if [ -z "$repo_url" ]; then
    repo_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"
  fi

  if [ -z "$repo_url" ]; then
    printf '%s\n' "Set CHEZMOI_REPO_URL or pass the repo URL as the first argument."
    exit 1
  fi
fi

have_command() {
  command -v "$1" >/dev/null 2>&1
}

current_login_shell() {
  case "$(uname -s)" in
    Darwin)
      dscl . -read "/Users/$(id -un)" UserShell 2>/dev/null | awk '{print $2}'
      ;;
    Linux)
      getent passwd "$(id -un)" | awk -F: '{print $7}'
      ;;
    *)
      printf '%s\n' ""
      ;;
  esac
}

ensure_default_shell_is_zsh() {
  zsh_path="$(command -v zsh 2>/dev/null || true)"

  if [ -z "$zsh_path" ]; then
    return 0
  fi

  if [ "$(current_login_shell)" = "$zsh_path" ]; then
    return 0
  fi

  case "$(uname -s)" in
    Linux)
      if have_command usermod; then
        run_as_root usermod -s "$zsh_path" "$(id -un)"
      elif have_command chsh; then
        run_as_root chsh -s "$zsh_path" "$(id -un)"
      else
        printf '%s\n' "zsh was installed, but no shell-change tool was found."
        printf '%s\n' "Set your login shell to $(printf '%s' "$zsh_path") manually."
      fi
      ;;
    Darwin)
      if have_command chsh; then
        chsh -s "$zsh_path" "$(id -un)" || true
      fi
      ;;
  esac
}

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif have_command sudo; then
    sudo "$@"
  else
    printf '%s\n' "sudo is required to install packages on this machine."
    return 1
  fi
}

install_starship() {
  if ! have_command curl; then
    printf '%s\n' "curl is required to install Starship on Linux."
    return 1
  fi

  mkdir -p "$HOME/.local/bin"
  sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- -y -b "$HOME/.local/bin"
}

install_yazi_from_github_deb() {
  if ! have_command curl; then
    printf '%s\n' "curl is required to install Yazi from GitHub releases."
    return 1
  fi

  if ! have_command dpkg; then
    printf '%s\n' "dpkg is required to install the Yazi .deb fallback package."
    return 1
  fi

  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)
      yazi_arch="x86_64"
      ;;
    aarch64|arm64)
      yazi_arch="aarch64"
      ;;
    *)
      printf '%s\n' "Skipping Yazi fallback: unsupported architecture '$arch'."
      return 0
      ;;
  esac

  yazi_deb_url="https://github.com/sxyazi/yazi/releases/latest/download/yazi-${yazi_arch}-unknown-linux-gnu.deb"
  yazi_tmp_deb="$(mktemp /tmp/yazi.XXXXXX.deb)"

  if ! curl -fL -o "$yazi_tmp_deb" "$yazi_deb_url"; then
    rm -f "$yazi_tmp_deb"
    printf '%s\n' "Failed to download Yazi fallback package from GitHub releases."
    return 1
  fi

  if ! run_as_root dpkg -i "$yazi_tmp_deb"; then
    printf '%s\n' "Yazi .deb install reported missing dependencies, attempting apt fix-up..."
    run_as_root apt-get -f install -y || true
    run_as_root dpkg -i "$yazi_tmp_deb" || true
  fi

  rm -f "$yazi_tmp_deb"

  if have_command yazi; then
    return 0
  fi

  printf '%s\n' "Yazi fallback installation did not produce a usable 'yazi' binary."
  return 1
}

install_yazi_if_missing() {
  if have_command yazi; then
    return 0
  fi

  if have_command apt-get; then
    printf '%s\n' "Yazi package unavailable via apt sources; trying official GitHub .deb fallback..."
    install_yazi_from_github_deb || true
  fi
}

refresh_debian_griffo_repo_key() {
  key_file="/etc/apt/trusted.gpg.d/debian.griffo.io.gpg"

  if ! have_command curl || ! have_command gpg; then
    return 0
  fi

  key_tmp="$(mktemp /tmp/debian-griffo-key.XXXXXX.asc)"
  if ! curl -fsSL -o "$key_tmp" "https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc"; then
    rm -f "$key_tmp"
    return 0
  fi

  run_as_root gpg --dearmor --yes -o "$key_file" "$key_tmp" || true
  rm -f "$key_tmp"
}

disable_debian_griffo_sources() {
  disabled_any=0

  for source_file in /etc/apt/sources.list.d/*; do
    [ -f "$source_file" ] || continue

    if grep -q "debian.griffo.io" "$source_file"; then
      disabled_file="${source_file}.disabled-by-bootstrap"
      run_as_root mv "$source_file" "$disabled_file"
      printf '%s\n' "Disabled broken apt source: $source_file"
      disabled_any=1
    fi
  done

  [ "$disabled_any" -eq 1 ]
}

safe_apt_update() {
  if run_as_root apt-get update; then
    return 0
  fi

  refresh_debian_griffo_repo_key
  if run_as_root apt-get update; then
    return 0
  fi

  if disable_debian_griffo_sources; then
    printf '%s\n' "Retrying apt update after disabling debian.griffo.io sources..."
    run_as_root apt-get update
    return $?
  fi

  return 1
}

install_packages_with_apt() {
  safe_apt_update
  for package in "$@"; do
    if ! run_as_root apt-get install -y "$package"; then
      printf '%s\n' "Skipping unavailable apt package: $package"
    fi
  done
}

install_packages_with_dnf() {
  for package in "$@"; do
    if ! run_as_root dnf install -y "$package"; then
      printf '%s\n' "Skipping unavailable dnf package: $package"
    fi
  done
}

install_packages_with_pacman() {
  run_as_root pacman -Sy --noconfirm
  for package in "$@"; do
    if ! run_as_root pacman -S --noconfirm --needed "$package"; then
      printf '%s\n' "Skipping unavailable pacman package: $package"
    fi
  done
}

install_packages_with_zypper() {
  for package in "$@"; do
    if ! run_as_root zypper --non-interactive install "$package"; then
      printf '%s\n' "Skipping unavailable zypper package: $package"
    fi
  done
}

install_packages_with_apk() {
  run_as_root apk update
  for package in "$@"; do
    if ! run_as_root apk add "$package"; then
      printf '%s\n' "Skipping unavailable apk package: $package"
    fi
  done
}

install_macos_dependencies() {
  if ! have_command brew; then
    NONINTERACTIVE=1 CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if ! have_command brew; then
    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$brew_path" ]; then
        PATH="$(dirname "$brew_path"):$PATH"
        export PATH
        break
      fi
    done
  fi

  if ! have_command brew; then
    printf '%s\n' "Homebrew installation failed or brew is not on PATH."
    return 1
  fi

  brew install $MACOS_PACKAGES
}

install_oh_my_zsh() {
  if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    return 0
  fi

  env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_plugin() {
  plugin_name="$1"
  plugin_repo="$2"
  plugin_dir="$HOME/.oh-my-zsh/custom/plugins/$plugin_name"

  if [ -d "$plugin_dir" ]; then
    return 0
  fi

  git clone --depth=1 "$plugin_repo" "$plugin_dir"
}

install_oh_my_zsh_plugins() {
  for plugin in $OMZ_PLUGINS; do
    case "$plugin" in
      zsh-autosuggestions)
        clone_plugin "$plugin" https://github.com/zsh-users/zsh-autosuggestions.git
        ;;
      zsh-syntax-highlighting)
        clone_plugin "$plugin" https://github.com/zsh-users/zsh-syntax-highlighting.git
        ;;
      zsh-completions)
        clone_plugin "$plugin" https://github.com/zsh-users/zsh-completions.git
        ;;
    esac
  done
}

install_linux_dependencies() {
  if have_command apt-get; then
    install_packages_with_apt $LINUX_BASE_PACKAGES $LINUX_TOOL_PACKAGES $APT_EXTRA_PACKAGES
    install_yazi_if_missing
  elif have_command dnf; then
    install_packages_with_dnf $LINUX_BASE_PACKAGES $LINUX_TOOL_PACKAGES $DNF_EXTRA_PACKAGES
  elif have_command pacman; then
    install_packages_with_pacman $LINUX_BASE_PACKAGES $LINUX_TOOL_PACKAGES $PACMAN_EXTRA_PACKAGES
  elif have_command zypper; then
    install_packages_with_zypper $LINUX_BASE_PACKAGES $LINUX_TOOL_PACKAGES $ZYPPER_EXTRA_PACKAGES
  elif have_command apk; then
    install_packages_with_apk $LINUX_BASE_PACKAGES $LINUX_TOOL_PACKAGES $APK_EXTRA_PACKAGES
  else
    printf '%s\n' "No supported Linux package manager was found."
    printf '%s\n' "Install git, zsh, curl, and ca-certificates manually, then rerun this script."
    return 1
  fi
}

case "$(uname -s)" in
  Darwin)
    if ! have_command brew; then
      printf '%s\n' "Install Homebrew first: https://brew.sh"
      exit 1
    fi
    install_macos_dependencies
    ;;
  Linux)
    install_linux_dependencies
    install_starship
    ensure_default_shell_is_zsh

    if ! have_command curl; then
      printf '%s\n' "curl is required to fetch chezmoi on Linux. Install curl and retry."
      exit 1
    fi
    ;;
  *)
    printf '%s\n' "Unsupported platform: $(uname -s)"
    exit 1
    ;;
esac

if have_command curl && have_command git; then
  install_oh_my_zsh
  install_oh_my_zsh_plugins
else
  printf '%s\n' "curl and git are required to install Oh My Zsh and its plugins."
  exit 1
fi

if [ "$install_only" -eq 1 ]; then
  exit 0
fi

if command -v chezmoi >/dev/null 2>&1; then
  chezmoi init --apply "$repo_url"
else
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$repo_url"
fi
