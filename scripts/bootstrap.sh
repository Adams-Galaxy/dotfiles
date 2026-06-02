#!/usr/bin/env sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
repo_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null || true)"

if [ -z "$repo_url" ]; then
  printf '%s\n' "No git remote found for $repo_dir. Set the repo URL in scripts/bootstrap.sh before running it."
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      printf '%s\n' "Install Homebrew first: https://brew.sh"
      exit 1
    fi
    brew install chezmoi git zsh
    ;;
  Linux)
    if ! command -v curl >/dev/null 2>&1; then
      printf '%s\n' "curl is required to bootstrap chezmoi on Linux. Install curl and retry."
      exit 1
    fi
    ;;
  *)
    printf '%s\n' "Unsupported platform: $(uname -s)"
    exit 1
    ;;
esac

if command -v chezmoi >/dev/null 2>&1; then
  chezmoi init --apply "$repo_url"
else
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply "$repo_url"
fi
