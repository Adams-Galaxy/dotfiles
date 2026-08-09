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

# Attach to a tmux session
tma() {
    local session="$1"

    if [[ -n "$session" ]]; then
        tmux attach-session -t "$session"
    else
        tmux attach-session
    fi
}

tmk() {
    local session="$1"

    if [[ -n "$session" ]]; then
        tmux kill-session -t "$session"
    else
        tmux kill-session
    fi
}

tmn() {
    local session="$1"

    if [[ -n "$session" ]]; then
        tmux new-session -s "$session"
    else
        tmux new-session
    fi
}

tmr() {
    local session="$1"

    if [[ -n "$session" ]]; then
        tmux rename-session -t "$session" "$2"
    else
        echo "Please provide a session name to rename."
    fi
}

# List tmux sessions currently running, one row per window, through gum
# table — real column alignment rather than markdown headers/bullets.
# Colors come from GUM_TABLE_* (common.zsh), not flags here, so this
# stays in sync with anything else that starts using gum table later.
tmls() {
    emulate -L zsh

    local sessions
    sessions=$(tmux list-sessions -F '#{session_name}	#{session_windows}	#{session_attached}' 2>/dev/null)
    if [[ -z "$sessions" ]]; then
        echo "No tmux sessions running."
        return 1
    fi

    local rows="" name windows attached attach_mark idx wname active active_mark panes
    while IFS=$'\t' read -r name windows attached; do
        attach_mark=""
        [[ "$attached" == "1" ]] && attach_mark="✓"

        while IFS=$'\t' read -r idx wname active panes; do
            active_mark=""
            [[ "$active" == "1" ]] && active_mark="✓"
            rows+="${name}	${idx}: ${wname}	${panes}	${active_mark}	${attach_mark}"$'\n'
        done < <(tmux list-windows -t "$name" -F '#{window_index}	#{window_name}	#{window_active}	#{window_panes}')
    done <<<"$sessions"

    # --print: this is a display command, not a picker — skip gum table's
    # default interactive row-selection UI (which also needs a real tty,
    # unlike a plain static render) and just print it.
    print -rn -- "$rows" | gum table -s $'\t' -c "Session,Window,Panes,Active,Attached" --print
}
