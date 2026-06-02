# macOS-specific config

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export STM32CubeMX_PATH="/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources"

# Bob is my home desktop computer. Say hi to Bob!
export BOB_REMOTE="adamsgalaxy.ddns.net"
export BOB_LOCAL="BOB.home"

set_bob_endpoint() {
  local ssid
  ssid="$(networksetup -getairportnetwork en0 | sed 's/^.*: //')"

  if [[ "$ssid" == "$HOME_SSID" ]]; then
    export BOB="$BOB_LOCAL"
  else
    export BOB="$BOB_REMOTE"
  fi
}

set_bob_endpoint

alias bob="ssh bob"
