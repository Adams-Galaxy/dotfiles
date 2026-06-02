# macOS-specific config

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

export STM32CubeMX_PATH="/Applications/STMicroelectronics/STM32CubeMX.app/Contents/Resources"

export DESKTOP_REMOTE="adamsgalaxy.ddns.net"
export DESKTOP_LOCAL="desktop.home"

set_desktop_endpoint() {
  local gateway
  gateway="$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2; exit}')"

  if [[ "$gateway" == "192.168.1.1" ]]; then
    export DESKTOP="$DESKTOP_LOCAL"
  else
    export DESKTOP="$DESKTOP_REMOTE"
  fi
}

set_desktop_endpoint

alias desktop="ssh adam@$DESKTOP"
