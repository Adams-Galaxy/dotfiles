#!/usr/bin/env sh
set -eu

if [ -f "$HOME/.antidote/antidote.zsh" ]; then
  exit 0
fi

git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
