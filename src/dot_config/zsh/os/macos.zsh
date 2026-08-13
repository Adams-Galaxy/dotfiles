# macOS-specific config

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export STM32CubeMX_PATH="/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources"

# WezTerm.app bundles its CLI inside the app rather than installing it to
# a standard bin dir (no cask/formula involved — see dot_config/wezterm/).
if [[ -d "/Applications/WezTerm.app/Contents/MacOS" ]]; then
  path_prepend "/Applications/WezTerm.app/Contents/MacOS"
fi

# Bob is my home desktop computer. Say hi to Bob!
# Home-vs-remote hostname selection lives in ~/.ssh/config, which picks the
# LAN address via a `Match host bob exec` SSID check. Doing it there means
# it's resolved per-connection (correct if the network changes mid-session)
# and costs nothing at shell startup, instead of shelling out to
# `networksetup` on every single shell.
alias bob="ssh bob"
