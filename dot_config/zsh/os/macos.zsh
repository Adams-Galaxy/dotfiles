# macOS-specific config

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export STM32CubeMX_PATH="/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources"

# Bob is my home desktop computer. Say hi to Bob!
# Home-vs-remote hostname selection lives in ~/.ssh/config, which picks the
# LAN address via a `Match host bob exec` SSID check. Doing it there means
# it's resolved per-connection (correct if the network changes mid-session)
# and costs nothing at shell startup, instead of shelling out to
# `networksetup` on every single shell.
alias bob="ssh bob"
