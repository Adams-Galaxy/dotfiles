# fzf-tab replaces Zsh's completion menu with an fzf picker.
# It must load after compinit; the plugin manifest records the matching order.

# fzf-tab drives selection itself, so zsh's own menu must be off.
zstyle ':completion:*' menu no

zstyle ':completion:*' group-order arguments options files directories

# Group header format ("[file]", "[directory]", ...) — fzf-tab parses
# these to build its groups.
zstyle ':completion:*:descriptions' format '[%d]'

# Colour candidates the way ls/eza would.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Don't re-sort git refs — git already returns them most-useful-first.
zstyle ':completion:*:git-checkout:*' sort false

# Reuse the gruvbox palette from $FZF_DEFAULT_OPTS (common.zsh) so the
# completion popup matches every other fzf surface.
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Cycle between groups (files / directories / options / ...).
zstyle ':fzf-tab:*' switch-group '<' '>'

# fzf-tab seeds the query with the candidates' shared prefix by default
# (e.g. "beta-" when beta-x/ and beta-y/ are both on screen), which makes
# the empty-query checks below fire far less than intended. An empty
# zstyle value — as opposed to an unset one — makes it skip that and
# start blank instead.
zstyle ':fzf-tab:*' query-string

# Tab navigates on an empty query, but accepts (like Enter) once you've
# typed something — typing is already a selection. Space (below, in
# fzf-flags) is the same idea in reverse: accepts on empty, else it's a
# literal space character.
#
# Space's transform doesn't live here alongside tab's: fzf's --bind
# parser breaks when two key:transform:... bindings share one
# comma-joined --bind value — *both* stop firing, not just the extras —
# verified directly against real fzf, nothing to do with fzf-tab's own
# quoting. fzf-tab always comma-joins everything in fzf-bindings into a
# single --bind, so a second transform has to go elsewhere: fzf-flags
# below is a separate argv token per entry, i.e. its own --bind flag,
# which sidesteps the bug.
zstyle ':fzf-tab:*' fzf-bindings \
  'tab:transform:[[ -z $FZF_QUERY ]] && echo down || echo accept' \
  'btab:up'

# Ctrl-L accepts the current item and reopens completion for the next segment.
# macOS reserves Ctrl-Space for input-source switching, so this is the portable
# advance binding across regular terminals, tmux, and Neovim terminals.
zstyle ':fzf-tab:*' continuous-trigger 'ctrl-l'

# Render into a floating window (nvim :terminal) or a tmux popup instead
# of redrawing the pane, so completion doesn't blow away scrollback. Falls
# back to inline fzf everywhere else. fzf runs borderless and its host
# draws the frame instead (styled to match fzf in .tmux.conf for tmux), so
# the two don't stack. -ftb-fzf also leaks a `--height` from
# $FZF_DEFAULT_OPTS through via the environment (argv-stripping doesn't
# catch it), shrinking things — stripped below in every popup path.

# $NVIM is set inside nvim's own :terminal regardless of whether that nvim
# is itself inside tmux — checked first in _ftb_popup below, so a terminal
# split inside tmux still gets a float sized to that split, not a tmux
# popup sized to the whole pane. Drives nvim's own RPC/floating-window API
# from ftb_popup.lua (dot_config/nvim/lua/config/); the shell side just
# builds the same kind of runner script ftb-tmux-popup writes (handles
# fzf's env/quoting once) and asks nvim to run it in a terminal job,
# blocking until that job exits.
_ftb_popup_nvim() {
  emulate -L zsh -o extended_glob

  if (( ! $+functions[zsh_math_func_min] )); then
    autoload -Uz zmathfunc
    zmathfunc
  fi

  : ${tmp_dir:=${TMPPREFIX:-/tmp/zsh}-fzf-tab-$USER}
  [[ -d $tmp_dir ]] || mkdir -p $tmp_dir

  if (( ! $+IN_FZF_TAB )); then
    cat > $tmp_dir/completions.$$
  fi

  # Same geometry ftb-tmux-popup gets from `tmux display-message`, sourced
  # from nvim instead: cursor's screen position (where the prompt actually
  # is, via screenpos() — not just the window's top-left) and the calling
  # window's own box.
  local -a geo=($(command nvim --server "$NVIM" --remote-expr "v:lua.__ftb_popup_geometry()" 2>/dev/null))
  if (( $#geo != 6 )); then
    fzf "$@"
    return
  fi
  local cursor_row=$geo[1] cursor_col=$geo[2] win_row=$geo[3] win_col=$geo[4]
  local win_width=$geo[5] win_height=$geo[6]
  local cursor_row_in_win=$(( cursor_row - win_row ))

  local -a fzf_opts=($@)
  fzf_opts=(${${fzf_opts/--height*}/--layout*})

  local popup_pad popup_min_size popup_max_lines
  zstyle -a ":fzf-tab:$_ftb_curcontext" popup-pad popup_pad || popup_pad=(0 0)
  zstyle -a ":fzf-tab:$_ftb_curcontext" popup-min-size popup_min_size || popup_min_size=(0 0)
  zstyle -s ":fzf-tab:$_ftb_curcontext" popup-max-lines popup_max_lines || popup_max_lines=0

  local comp_lines comp_length=0 length line
  comp_lines=$(( ${#${(f)mapfile[$tmp_dir/completions.$$]}} + $popup_pad[2] ))
  (( popup_max_lines > 0 && comp_lines > popup_max_lines )) && comp_lines=$popup_max_lines
  for line in ${(f)mapfile[$tmp_dir/completions.$$]}; do
    length=${(m)#${(S)line//$'\x1b['[0-9]#*m}}
    (( length >= comp_length )) && comp_length=$length
  done
  comp_length=$(( comp_length + $popup_pad[1] ))

  # Same above/below-cursor choice as the pane fork: below is preferred
  # outright, shrinking down to a hard 4-row content minimum before
  # flipping above, rather than a midpoint heuristic that flips based on
  # cursor position alone.
  local popup_row popup_height popup_col popup_width
  local room_below=$(( win_height - cursor_row_in_win - 1 ))
  local content_floor=$(( comp_lines >= 4 ? 4 : comp_lines ))
  local hard_min=$(( content_floor + 4 ))

  if (( room_below >= hard_min )); then
    popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), room_below) ))
    popup_row=$(( cursor_row + 1 ))
  else
    popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), cursor_row_in_win) ))
    popup_row=$(( cursor_row - popup_height ))
  fi
  popup_width=$(( min(max(comp_length + 5, popup_min_size[1]), win_width) ))
  local win_right=$(( win_col + win_width ))
  popup_col=$(( cursor_col + popup_width > win_right ? win_right - popup_width : cursor_col ))

  # LINES/--height from -ftb-fzf reflect the terminal the shell started
  # in, not the floating window nvim is about to size this to — same
  # mismatch ftb-tmux-popup works around, same fix.
  local FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS//--height[= ]##[0-9]##(%|)/}"

  local script=$tmp_dir/fzf-nvim-$$
  local result=$tmp_dir/result-nvim-$$
  command rm -f $result
  command mkfifo $result
  print -r -- "env FZF_DEFAULT_OPTS=${(qq)FZF_DEFAULT_OPTS} SHELL=$ZSH_NAME $commands[fzf] ${(qq)fzf_opts[@]} < $tmp_dir/completions.$$ > $result" > $script

  # __ftb_popup_open returns as soon as the job starts, not when it
  # finishes (see ftb_popup.lua for why) — so wait on the fifo instead of
  # nvim's response: opening it for read blocks until fzf (writing the
  # script's redirected stdout) opens the other end, and reading it blocks
  # until fzf exits and closes it. A kernel-level wait, no polling on
  # either side.
  command nvim --server "$NVIM" --remote-expr \
    "v:lua.__ftb_popup_open($popup_row, $popup_col, $popup_width, $popup_height, \"$script\", \"$PWD\")" \
    >/dev/null 2>&1

  echo -E "$(<$result)"

  command rm -f $script $result
  (( $+IN_FZF_TAB )) || command rm -f $tmp_dir/completions.$$
}

# No tmux, no nvim :terminal — nothing to size a box against, fzf just
# draws inline below the prompt. But plain `fzf "$@"` leaves the static
# `--height=90%` from fzf-flags in charge, which is exactly the same "fixed
# slice regardless of content" problem the popup paths avoid: a 3-line `cd`
# list still eats 90% of the terminal. Same comp_lines-driven height as the
# popup paths, minus all the position/width math those need and this
# doesn't — inline fzf already spans the terminal's own width, there's no
# separate box to size horizontally.
_ftb_popup_plain() {
  emulate -L zsh -o extended_glob

  if (( ! $+functions[zsh_math_func_min] )); then
    autoload -Uz zmathfunc
    zmathfunc
  fi

  : ${tmp_dir:=${TMPPREFIX:-/tmp/zsh}-fzf-tab-$USER}
  [[ -d $tmp_dir ]] || mkdir -p $tmp_dir

  if (( ! $+IN_FZF_TAB )); then
    cat > $tmp_dir/completions.$$
  fi

  local -a fzf_opts=($@)
  fzf_opts=(${${fzf_opts/--height*}/--layout*})

  local popup_min_size popup_max_lines
  zstyle -a ":fzf-tab:$_ftb_curcontext" popup-min-size popup_min_size || popup_min_size=(0 0)
  zstyle -s ":fzf-tab:$_ftb_curcontext" popup-max-lines popup_max_lines || popup_max_lines=0

  local comp_lines=$(( ${#${(f)mapfile[$tmp_dir/completions.$$]}} ))
  (( popup_max_lines > 0 && comp_lines > popup_max_lines )) && comp_lines=$popup_max_lines
  local popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), LINES - 1) ))
  fzf_opts+=(--height=$popup_height)

  {
    fzf $fzf_opts < $tmp_dir/completions.$$
  } always {
    (( $+IN_FZF_TAB )) || command rm -f $tmp_dir/completions.$$
  }
}

if [[ -n "$TMUX" ]]; then
  # ftb-tmux-popup sizes/positions against the whole tmux window, so by
  # default the popup can grow past the pane it opened in. Set
  # popup-bounds to 'pane' to confine it to the host pane instead.
  # There's no upstream zstyle for this — the window bound is hardcoded —
  # so _ftb_popup_pane is a copy of ftb-tmux-popup with pane_* substituted
  # for window_*, not a patch to it. Can drift if fzf-tab changes that
  # script, but only for whoever opts into 'pane'.
  _ftb_popup_pane() {
    emulate -L zsh -o extended_glob

    if (( ! $+functions[zsh_math_func_min] )); then
      autoload -Uz zmathfunc
      zmathfunc
    fi

    : ${tmp_dir:=${TMPPREFIX:-/tmp/zsh}-fzf-tab-$USER}

    if (( ! $+TMUX_PANE )); then
      fzf $@
      return
    fi

    local ret=0
    local -a fzf_opts=($@)
    fzf_opts=(${${fzf_opts/--height*}/--layout*})

    local -a tmp=($(command tmux display-message -p "#{pane_top} #{cursor_y} #{pane_left} #{cursor_x} #{pane_height} #{pane_width} #{status} #{status-position}"))
    local pane_top=$tmp[1] cursor_y_in_pane=$tmp[2] pane_left=$tmp[3]
    local pane_height=$tmp[5] pane_width=$tmp[6] window_top=0
    local cursor_y=$((pane_top + cursor_y_in_pane)) cursor_x=$((pane_left + tmp[4]))

    # #{cursor_y}/#{pane_top} are relative to the pane's own content area,
    # which doesn't include the status bar even when it's docked at the
    # top — but `tmux popup -y` is in absolute screen rows, which does. A
    # top status bar needs a 1-row correction to convert between the two;
    # $tmp[7] (#{status}) is 'on'/'off', not a row count — using it
    # directly as the offset (the form this was copied from) throws "bad
    # math expression" whenever the status bar is docked top, and having
    # silently failed, leaves cursor_y one row short of where the pane
    # actually starts on screen for the rest of the popup's positioning.
    if [[ $tmp[7] == 'on' && $tmp[8] == 'top' ]]; then
      window_top=1
      cursor_y=$((cursor_y + window_top))
    fi

    if (( ! $+IN_FZF_TAB )); then
      [[ -d $tmp_dir ]] || mkdir -p $tmp_dir
      cat > $tmp_dir/completions.$$
    fi

    local text REPLY comp_lines comp_length length popup_pad popup_min_size popup_max_lines

    zstyle -a ":fzf-tab:$_ftb_curcontext" popup-pad popup_pad || popup_pad=(0 0)
    zstyle -a ":fzf-tab:$_ftb_curcontext" popup-min-size popup_min_size || popup_min_size=(0 0)
    zstyle -s ":fzf-tab:$_ftb_curcontext" popup-max-lines popup_max_lines || popup_max_lines=0

    comp_lines=$(( ${#${(f)mapfile[$tmp_dir/completions.$$]}} + $popup_pad[2] ))
    (( popup_max_lines > 0 && comp_lines > popup_max_lines )) && comp_lines=$popup_max_lines
    if (( comp_lines <= 500 )); then
      comp_length=0
      for line in ${(f)mapfile[$tmp_dir/completions.$$]}; do
        length=${(m)#${(S)line//$'\x1b['[0-9]#*m}}
        (( length >= comp_length )) && comp_length=$length
      done
    else
      comp_length=$( command perl -ne 's/\x1b\[[0-9;]*m//g;s/\x00//g; $m= length() if $m < length(); END { print $m }' < $tmp_dir/completions.$$ )
    fi
    comp_length=$(( comp_length + $popup_pad[1] ))

    local popup_height popup_y popup_width popup_x adjust_height

    if (( $fzf_opts[(I)--info=*(hidden|inline)*] > 0 )); then
      adjust_height=-1
    fi

    # Below is preferred outright, shrinking to fit rather than flipping
    # above — the old cursor-past-midpoint heuristic flipped to "above"
    # purely off cursor position, with no regard for whether the content
    # would actually have fit below at a reasonable size, so a short pane
    # (where the midpoint sits close to the top) flipped for nearly every
    # completion. Only when even a hard 4-row minimum (fewer if there are
    # fewer than 4 real candidates) won't fit in the room below does it
    # move above; cursor_y_in_pane is the room above the cursor within the
    # pane, pane_height - cursor_y_in_pane - 1 is the room below.
    local room_below=$(( pane_height - cursor_y_in_pane - 1 ))
    local content_floor=$(( comp_lines >= 4 ? 4 : comp_lines ))
    local hard_min=$(( content_floor + 4 + adjust_height ))

    if (( room_below >= hard_min )); then
      popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), room_below) + adjust_height ))
      popup_y=$(( cursor_y + popup_height + 1 ))
      fzf_opts+=(--layout=reverse)
    else
      popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), cursor_y_in_pane) + adjust_height ))
      popup_y=$cursor_y
      if zstyle -T ":fzf-tab:$_ftb_curcontext" popup-smart-tab; then
        fzf_opts+=(--bind=tab:up,btab:down)
      fi
      fzf_opts+=(--layout=default)
    fi

    popup_width=$(( min(max(comp_length + 5, popup_min_size[1]), pane_width) ))
    local pane_right=$(( pane_left + pane_width ))
    popup_x=$(( cursor_x + popup_width > pane_right ? pane_right - popup_width : cursor_x ))

    echo -E "env FZF_DEFAULT_OPTS=${(qq)FZF_DEFAULT_OPTS} SHELL=$ZSH_NAME $commands[fzf] ${(qq)fzf_opts[@]} < $tmp_dir/completions.$$ > $tmp_dir/result-$$" > $tmp_dir/fzf-$$
    {
      tmux popup -x $popup_x -y $popup_y \
           -w $popup_width -h $popup_height \
           -d $PWD -E ". $tmp_dir/fzf-$$" || ret=$?
      echo -E "$(<$tmp_dir/result-$$)"
    } always {
      command rm $tmp_dir/*-$$
      (( $+IN_FZF_TAB )) || command rm $tmp_dir/completions.$$
    }
    return $ret
  }

  # Same as _ftb_popup_pane, but against the whole window instead of just
  # the host pane — a copy of upstream's ftb-tmux-popup (window_* fields,
  # otherwise identical math) rather than a patch to it, for the same
  # reason: popup-max-lines isn't an upstream zstyle either, so getting it
  # to apply in the default (window) bounds mode needs its own copy of the
  # sizing to hook into, same as popup-bounds did for pane mode.
  _ftb_popup_window() {
    emulate -L zsh -o extended_glob

    if (( ! $+functions[zsh_math_func_min] )); then
      autoload -Uz zmathfunc
      zmathfunc
    fi

    : ${tmp_dir:=${TMPPREFIX:-/tmp/zsh}-fzf-tab-$USER}

    if (( ! $+TMUX_PANE )); then
      fzf $@
      return
    fi

    local ret=0
    local -a fzf_opts=($@)
    fzf_opts=(${${fzf_opts/--height*}/--layout*})

    local -a tmp=($(command tmux display-message -p "#{pane_top} #{cursor_y} #{pane_left} #{cursor_x} #{window_height} #{window_width} #{status} #{status-position}"))
    local cursor_y=$((tmp[1] + tmp[2])) cursor_x=$((tmp[3] + tmp[4]))
    local window_height=$tmp[5] window_width=$tmp[6] window_top=0

    # See the matching comment in _ftb_popup_pane: $tmp[7] (#{status}) is
    # 'on'/'off', not a row count, so using it directly as the offset
    # throws "bad math expression" whenever the status bar is docked top —
    # which then leaves cursor_y (and everything computed from it) wrong,
    # not merely unadjusted.
    if [[ $tmp[7] == 'on' && $tmp[8] == 'top' ]]; then
      window_top=1
      cursor_y=$((cursor_y + window_top))
    fi

    if (( ! $+IN_FZF_TAB )); then
      [[ -d $tmp_dir ]] || mkdir -p $tmp_dir
      cat > $tmp_dir/completions.$$
    fi

    local text REPLY comp_lines comp_length length popup_pad popup_min_size popup_max_lines

    zstyle -a ":fzf-tab:$_ftb_curcontext" popup-pad popup_pad || popup_pad=(0 0)
    zstyle -a ":fzf-tab:$_ftb_curcontext" popup-min-size popup_min_size || popup_min_size=(0 0)
    zstyle -s ":fzf-tab:$_ftb_curcontext" popup-max-lines popup_max_lines || popup_max_lines=0

    comp_lines=$(( ${#${(f)mapfile[$tmp_dir/completions.$$]}} + $popup_pad[2] ))
    (( popup_max_lines > 0 && comp_lines > popup_max_lines )) && comp_lines=$popup_max_lines
    if (( comp_lines <= 500 )); then
      comp_length=0
      for line in ${(f)mapfile[$tmp_dir/completions.$$]}; do
        length=${(m)#${(S)line//$'\x1b['[0-9]#*m}}
        (( length >= comp_length )) && comp_length=$length
      done
    else
      comp_length=$( command perl -ne 's/\x1b\[[0-9;]*m//g;s/\x00//g; $m= length() if $m < length(); END { print $m }' < $tmp_dir/completions.$$ )
    fi
    comp_length=$(( comp_length + $popup_pad[1] ))

    local popup_height popup_y popup_width popup_x adjust_height

    if (( $fzf_opts[(I)--info=*(hidden|inline)*] > 0 )); then
      adjust_height=-1
    fi

    # See _ftb_popup_pane: below is preferred outright, shrinking down to a
    # hard 4-row content minimum before flipping above, rather than a
    # midpoint heuristic that flips based on cursor position alone.
    local room_below=$(( window_height - cursor_y + window_top - 1 ))
    local content_floor=$(( comp_lines >= 4 ? 4 : comp_lines ))
    local hard_min=$(( content_floor + 4 + adjust_height ))

    if (( room_below >= hard_min )); then
      popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), room_below) + adjust_height ))
      popup_y=$(( cursor_y + popup_height + 1 ))
      fzf_opts+=(--layout=reverse)
    else
      popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), cursor_y - window_top) + adjust_height ))
      popup_y=$cursor_y
      if zstyle -T ":fzf-tab:$_ftb_curcontext" popup-smart-tab; then
        fzf_opts+=(--bind=tab:up,btab:down)
      fi
      fzf_opts+=(--layout=default)
    fi

    popup_width=$(( min(max(comp_length + 5, popup_min_size[1]), window_width) ))
    popup_x=$(( cursor_x + popup_width > window_width ? window_width - popup_width : cursor_x ))

    echo -E "env FZF_DEFAULT_OPTS=${(qq)FZF_DEFAULT_OPTS} SHELL=$ZSH_NAME $commands[fzf] ${(qq)fzf_opts[@]} < $tmp_dir/completions.$$ > $tmp_dir/result-$$" > $tmp_dir/fzf-$$
    {
      tmux popup -x $popup_x -y $popup_y \
           -w $popup_width -h $popup_height \
           -d $PWD -E ". $tmp_dir/fzf-$$" || ret=$?
      echo -E "$(<$tmp_dir/result-$$)"
    } always {
      command rm $tmp_dir/*-$$
      (( $+IN_FZF_TAB )) || command rm $tmp_dir/completions.$$
    }
    return $ret
  }

fi

# Dispatches to whichever host can draw a floating/popup container: nvim's
# own :terminal takes priority over tmux (see _ftb_popup_nvim above — a
# terminal split inside tmux should still get a window-sized float, not a
# pane-sized tmux popup), then tmux if present, else plain inline fzf.
# Registered unconditionally so standalone (non-tmux) nvim still gets it.
_ftb_popup() {
  emulate -L zsh
  setopt local_options extended_glob

  if [[ -n "$NVIM" ]]; then
    _ftb_popup_nvim "$@"
    return
  fi

  if [[ -z "$TMUX" ]]; then
    _ftb_popup_plain "$@"
    return
  fi

  local FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS//--height[= ]##[0-9]##(%|)/}"
  export FZF_DEFAULT_OPTS

  local popup_bounds
  zstyle -s ':fzf-tab:*' popup-bounds popup_bounds || popup_bounds=window

  if [[ "$popup_bounds" == pane ]]; then
    _ftb_popup_pane "$@"
  else
    _ftb_popup_window "$@"
  fi
}

zstyle ':fzf-tab:*' fzf-command _ftb_popup

# Preview gets more room than the list — candidate names/paths are almost
# always far narrower than what they preview (a full file, a diff, ...).
# fzf can't size this off actual content, but its SIZE_THRESHOLD clause
# gives a two-tier approximation: below 100 columns there's rarely enough
# width to spare, so it's an even 50/50; above that, the extra room goes
# to the preview at 70/30 rather than growing both sides proportionally.
#
# --border/--info only matter inside a tmux popup or an nvim float, where
# the host already draws a frame. The no-tmux/no-nvim fallback (plain
# inline fzf, _ftb_popup_plain above) gets its height from popup-min-size
# the same way the popup paths do, not a flag here.
() {
  local -a flags=(
    --preview-window='right,70%,<100(right,50%)'
    --bind='space:transform:[[ -z $FZF_QUERY ]] && echo accept || echo "put( )"'
  )
  if [[ -n "$NVIM" || -n "$TMUX" ]]; then
    flags+=(--border=none --info=inline)
  fi
  zstyle ':fzf-tab:*' fzf-flags $flags

  # kill mirrors fkill (fzf.zsh): --multi to pick several PIDs at once,
  # inserted onto the command line space-separated rather than fkill's own
  # immediate `xargs kill` — Tab only ever edits the line here, same as
  # every other completion, so the actual kill still needs its own Enter.
  # A more specific zstyle context replaces the global fzf-flags/fzf-bindings
  # above outright rather than merging with them, so both need repeating
  # here alongside what's new.
  flags+=(--multi --prompt='kill> ' --header='Select processes with Tab')
  zstyle ':fzf-tab:complete:kill:*' fzf-flags $flags

  # Tab reverts to fzf's own --multi default (toggle selection, move down)
  # instead of the global accept/navigate transform, so it can actually
  # multi-select here; arrows and fzf's built-in ctrl-j/ctrl-k still move
  # without toggling.
  zstyle ':fzf-tab:complete:kill:*' fzf-bindings \
    'tab:toggle+down' \
    'btab:toggle+up'
}

# --- Previews ---------------------------------------------------------
# $realpath is the candidate's resolved path; $word is the raw candidate.

zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza -1 --color=always --icons=always $realpath'
# zoxide's `cd` is a function, so it completes under its own name.
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview \
  'eza -1 --color=always --icons=always $realpath'

zstyle ':fzf-tab:complete:(nvim|vim|nano|bat|cat|less|cp|mv|rm|code|source|ls):*' fzf-preview \
  '[[ -d $realpath ]] && eza -1 --color=always --icons=always $realpath || bat --color=always --style=numbers --line-range=:300 $realpath 2>/dev/null'

zstyle ':fzf-tab:complete:(export|unset|printenv|echo):*' fzf-preview \
  'echo ${(P)word}'

# Through delta so it matches the pager configured in git config.
zstyle ':fzf-tab:complete:git-(add|diff|restore|stage|checkout|switch):*' fzf-preview \
  'git diff --color=always $word 2>/dev/null | delta || eza -1 --color=always --icons=always $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:git-(show|log):*' fzf-preview \
  'git show --color=always $word 2>/dev/null | delta'

# kill gets no preview at all — with the `command`/verbose overrides below,
# the candidate line already *is* the full ps row, so a preview pane would
# just be showing the same command a second time while eating half the
# width. ps's own completion still gets one: unlike kill, its candidates
# aren't already the full ps line.
zstyle ':fzf-tab:complete:ps:argument-rest' fzf-preview \
  'ps -p $word -o command= 2>/dev/null'

# `_kill` gets its candidates from `_pids`, which shells out via
# _call_program's own zstyle hook (`:completion:<ctx>:processes` command) —
# not an fzf-tab style at all, but the same lever fkill (fzf.zsh) pulls
# directly. Same columns here so kill's Tab-list reads identically; verbose
# makes _pids use the full ps line as the candidate text instead of a bare
# pid.
zstyle ':completion:*:*:kill:*:processes' command \
  'ps -Ao pid,user,%cpu,%mem,command'
zstyle ':completion:*:*:kill:*:processes' verbose yes

zstyle ':fzf-tab:complete:(man|where|which|type):*' fzf-preview \
  'man $word 2>/dev/null | head -100'

# --- Preview sizing ---------------------------------------------------
# Popup width is derived purely from the longest candidate, with no idea
# a preview pane is coming — a short candidate list (e.g. one file in a
# big nvim tab) gets a small popup regardless of how much room a preview
# like a full file actually wants. min(max(content, floor), bound) means a
# floor bigger than any real bound just clamps down to the bound.
#
# That's the right move for a preview that *is* the point (a file, a
# diff) — but most previews here are closer to a fact than a document (a
# directory listing, one env value, a process's command line, a man
# page): flooring those the same way just makes `cd <Tab>` needlessly
# fill the screen for three folder names. So this is two tiers, not one
# floor for every preview-having context: contexts whose preview shows
# real content get maximised, the rest get a little headroom over
# content-only sizing and nothing more.
#
# 'free' drops both floors entirely and returns to fzf-tab's own
# content-only sizing. Override in local.zsh, read before the default
# below so it wins: `zstyle ':fzf-tab:*' popup-sizing free`.
() {
  local ctx popup_sizing
  zstyle -s ':fzf-tab:*' popup-sizing popup_sizing || popup_sizing=constrained
  [[ "$popup_sizing" == constrained ]] || return 0

  # The preview is the whole point — maximise.
  for ctx in \
    '(nvim|vim|nano|bat|cat|less|cp|mv|rm|code|source|ls)' \
    'git-(add|diff|restore|stage|checkout|switch)' \
    'git-(show|log)'
  do
    zstyle ":fzf-tab:complete:${ctx}:*" popup-min-size 9999 9999
  done

  # The preview is a fact, not a document — enough room to read it
  # comfortably, not a maximised window. Also capped at 16 rows of actual
  # candidates regardless of how many there are or how much room the
  # window/pane has: past that, fuzzy-searching is faster than scrolling a
  # taller box anyway, so growing further just costs screen space for no
  # real benefit. popup-max-lines caps comp_lines itself (pre floor/bound),
  # so it composes with the floor above rather than fighting it — same
  # override mechanism as popup-min-size, so any one context can still ask
  # for more via its own more-specific zstyle.
  for ctx in \
    'cd' \
    '__zoxide_z' \
    '(export|unset|printenv|echo)' \
    '(kill|ps)' \
    '(man|where|which|type)'
  do
    zstyle ":fzf-tab:complete:${ctx}:*" popup-min-size 60 12
    zstyle ":fzf-tab:complete:${ctx}:*" popup-max-lines 16
  done
}
