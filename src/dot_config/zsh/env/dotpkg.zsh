# Manage the bootstrap package manifest (scripts/packages.conf)

dotpkg() {
  local manifest="$CHEZMOI_SOURCE_DIR/scripts/packages.conf"
  local cmd="${1:-}"
  [[ $# -gt 0 ]] && shift

  case "$cmd" in
    add)
      local name="${1:-}"
      [[ $# -gt 0 ]] && shift

      local profiles=""
      local -A overrides
      local arg key value

      for arg in "$@"; do
        case "$arg" in
          --profiles=*) profiles="${arg#--profiles=}" ;;
          --brew=*|--apt=*|--dnf=*|--pacman=*|--zypper=*|--apk=*)
            key="${arg%%=*}"
            key="${key#--}"
            value="${arg#*=}"
            overrides[$key]="$value"
            ;;
          *)
            print -u2 "Unknown argument: $arg"
            return 1
            ;;
        esac
      done

      if [[ -z "$name" || -z "$profiles" ]]; then
        print -u2 "Usage: dotpkg add <name> --profiles=macos,linux [--brew=name] [--apt=name] [--dnf=name] [--pacman=name] [--zypper=name] [--apk=name]"
        return 1
      fi

      if awk -v name="$name" '$1 == name { found = 1 } END { exit !found }' "$manifest"; then
        print -u2 "Package '$name' already exists in $manifest"
        return 1
      fi

      local override_str="-"
      local pairs=()
      for key in brew apt dnf pacman zypper apk; do
        [[ -n "${overrides[$key]:-}" ]] && pairs+=("$key=${overrides[$key]}")
      done
      (( ${#pairs} > 0 )) && override_str="${(j:,:)pairs}"

      printf '%-16s %-13s %s\n' "$name" "$profiles" "$override_str" >> "$manifest"
      print "Added $name ($profiles) to $manifest"
      ;;

    remove)
      local name="${1:-}"
      if [[ -z "$name" ]]; then
        print -u2 "Usage: dotpkg remove <name>"
        return 1
      fi

      local tmp
      tmp="$(mktemp)"
      awk -v name="$name" '$1 != name' "$manifest" > "$tmp" && mv "$tmp" "$manifest"
      print "Removed $name from $manifest (if present)"
      ;;

    list)
      grep -Ev '^[[:space:]]*(#|$)' "$manifest" | column -t
      ;;

    *)
      print -u2 "Usage: dotpkg <add|remove|list> ..."
      return 1
      ;;
  esac
}
