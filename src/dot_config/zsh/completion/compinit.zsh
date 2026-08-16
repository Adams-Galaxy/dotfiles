# Initialise completion once fpath contains local and pre-plugin functions.

autoload -Uz compinit
() {
  emulate -L zsh
  setopt local_options extended_glob

  local -a stale
  stale=( ${ZSH_COMPDUMP}(#qN.mh+24) )

  if (( ${#stale} )) || [[ ! -f "$ZSH_COMPDUMP" ]]; then
    compinit -d "$ZSH_COMPDUMP"
    # The daily audited rebuild keeps startup fast without permanently
    # suppressing compaudit's insecure-directory check.
    { zcompile -R -- "$ZSH_COMPDUMP".zwc "$ZSH_COMPDUMP" } &!
  else
    compinit -C -d "$ZSH_COMPDUMP"
  fi
}
