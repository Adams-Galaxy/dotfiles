# tmux workflow helpers

# Manage $PANE_SETUP, the per-pane command that `prefix + R` re-runs across
# every pane in the window (see dot_tmux.conf.tmpl). Each pane sets its own
# value, so a single broadcast keystroke re-runs a different command per pane.
pane-setup() {
  case "$1" in
    set)
      shift
      if [[ $# -eq 0 ]]; then
        echo "Usage: pane-setup set <command...>"
        return 1
      fi
      export PANE_SETUP="$*"
      echo "PANE_SETUP set: $PANE_SETUP"
      ;;
    clear)
      unset PANE_SETUP
      echo "PANE_SETUP cleared"
      ;;
    show)
      if [[ -n "$PANE_SETUP" ]]; then
        echo "PANE_SETUP: $PANE_SETUP"
      else
        echo "PANE_SETUP not set"
      fi
      ;;
    *)
      echo "Usage: pane-setup <set <command...>|clear|show>"
      return 1
      ;;
  esac
}
