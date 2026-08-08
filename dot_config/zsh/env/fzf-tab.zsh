# fzf-tab — replaces zsh's completion menu with an fzf picker.
# Loaded from .zshrc after compinit; see zsh_plugins.txt for load order.

# fzf-tab drives selection itself, so zsh's own menu must be off.
zstyle ':completion:*' menu no

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
# typed something — typing is already a selection. Space is the same idea
# in reverse: accepts on empty, else it's a literal space character.
zstyle ':fzf-tab:*' fzf-bindings \
  'tab:transform:[[ -z $FZF_QUERY ]] && echo down || echo accept' \
  'btab:up' \
  'space:transform:[[ -z $FZF_QUERY ]] && echo accept || echo "put( )"'

# Ctrl-L accepts the current item and reopens completion for the next
# segment (fzf-tab's "continuous completion", normally on `/`). Vim-style:
# l reads as "advance". Originally ctrl-space, but macOS reserves that
# globally for input-source switching and swallows it before the terminal
# ever sees it — only `tmux send-keys` (which injects the byte directly)
# made it look like it worked under test.
zstyle ':fzf-tab:*' continuous-trigger 'ctrl-l'

# Inside tmux (>= 3.2) render into a popup instead of redrawing the pane.
# Falls back to inline fzf everywhere else.
#
# fzf runs borderless and the tmux popup keeps its border (styled to match
# fzf in .tmux.conf), so the two don't stack. -ftb-fzf also leaks a
# `--height` from $FZF_DEFAULT_OPTS through to the popup's fzf via the
# environment (argv-stripping doesn't catch it), shrinking it — stripped
# below before every popup invocation.
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

    if [[ $tmp[8] == 'top' ]]; then
      window_top=$tmp[7]
      cursor_y=$((cursor_y + window_top))
    fi

    if (( ! $+IN_FZF_TAB )); then
      [[ -d $tmp_dir ]] || mkdir -p $tmp_dir
      cat > $tmp_dir/completions.$$
    fi

    local text REPLY comp_lines comp_length length popup_pad popup_min_size

    zstyle -a ":fzf-tab:$_ftb_curcontext" popup-pad popup_pad || popup_pad=(0 0)
    zstyle -a ":fzf-tab:$_ftb_curcontext" popup-min-size popup_min_size || popup_min_size=(0 0)

    comp_lines=$(( ${#${(f)mapfile[$tmp_dir/completions.$$]}} + $popup_pad[2] ))
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

    # Bound against the pane's own box: cursor_y_in_pane is the room above
    # the cursor within the pane; pane_height - cursor_y_in_pane - 1 is
    # the room below.
    if (( cursor_y_in_pane * 2 > pane_height )); then
      popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), cursor_y_in_pane) + adjust_height ))
      popup_y=$cursor_y
      if zstyle -T ":fzf-tab:$_ftb_curcontext" popup-smart-tab; then
        fzf_opts+=(--bind=tab:up,btab:down)
      fi
      fzf_opts+=(--layout=default)
    else
      popup_height=$(( min(max(comp_lines + 4, popup_min_size[2]), pane_height - cursor_y_in_pane - 1) + adjust_height ))
      popup_y=$(( cursor_y + popup_height + 1 ))
      fzf_opts+=(--layout=reverse)
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

  _ftb_popup() {
    emulate -L zsh
    setopt local_options extended_glob
    local FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS//--height[= ]##[0-9]##(%|)/}"
    export FZF_DEFAULT_OPTS

    local popup_bounds
    zstyle -s ':fzf-tab:*' popup-bounds popup_bounds || popup_bounds=window

    if [[ "$popup_bounds" == pane ]]; then
      _ftb_popup_pane "$@"
    else
      ftb-tmux-popup "$@"
    fi
  }

  zstyle ':fzf-tab:*' fzf-command _ftb_popup
fi

# Preview gets more room than the list — candidate names/paths are almost
# always far narrower than what they preview (a full file, a diff, ...).
# fzf can't size this off actual content, but its SIZE_THRESHOLD clause
# gives a two-tier approximation: below 100 columns there's rarely enough
# width to spare, so it's an even 50/50; above that, the extra room goes
# to the preview at 70/30 rather than growing both sides proportionally.
# --border and --info only make sense inside a tmux popup, where tmux
# draws the frame instead (see above) — inline fzf keeps its own.
() {
  local -a flags=(--preview-window='right,70%,<100(right,50%)')
  [[ -n "$TMUX" ]] && flags+=(--border=none --info=inline)
  zstyle ':fzf-tab:*' fzf-flags $flags
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

zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  'ps -p $word -o command= 2>/dev/null'

zstyle ':fzf-tab:complete:(man|where|which|type):*' fzf-preview \
  'man $word 2>/dev/null | head -100'

# --- Preview sizing ---------------------------------------------------
# Popup width is derived purely from the longest candidate, with no idea
# a preview pane is coming — a short candidate list (e.g. one file in a
# big nvim tab) gets a small popup regardless of how much room a preview
# like a full file actually wants. min(max(content, floor), bound) means a
# floor bigger than any real bound just clamps down to the bound, so this
# sets one deliberately oversized rather than picking a fixed "comfortable"
# number — every preview-having context fills the available window/pane
# (see popup-bounds), not just whatever the candidates alone would need.
# 'free' drops this and returns to fzf-tab's own content-only sizing.
# Override in local.zsh, read before the default below so it wins:
# `zstyle ':fzf-tab:*' popup-sizing free`.
() {
  local ctx popup_sizing
  zstyle -s ':fzf-tab:*' popup-sizing popup_sizing || popup_sizing=constrained
  [[ "$popup_sizing" == constrained ]] || return 0

  for ctx in \
    'cd' \
    '__zoxide_z' \
    '(nvim|vim|nano|bat|cat|less|cp|mv|rm|code|source|ls)' \
    '(export|unset|printenv|echo)' \
    'git-(add|diff|restore|stage|checkout|switch)' \
    'git-(show|log)' \
    '(kill|ps)' \
    '(man|where|which|type)'
  do
    zstyle ":fzf-tab:complete:${ctx}:*" popup-min-size 9999 9999
  done
}
