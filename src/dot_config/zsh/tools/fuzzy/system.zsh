# Fuzzy system and environment pickers.

# Fuzzy kill function
fkill() {
    local signal="${1:-TERM}"
    local selected

    selected="$(
        ps -Ao pid,user,%cpu,%mem,command |
        sed 1d |
        fzf \
            --multi \
            --prompt="kill $signal> " \
            --header='Select processes with Tab'
    )" || return

    print -r -- "$selected" |
    awk '{print $1}' |
    xargs kill "-$signal"
}

# Fuzzy environment variable selection function
fenv() {
    local variable

    variable="$(
        env |
        sort |
        fzf \
            --prompt='env> ' \
            --delimiter='=' \
            --with-nth=1 \
            --preview='echo {}'
    )" || return

    print -r -- "$variable"
}

# Fuzzy environment variable copy function
fenvcopy() {
    local value

    value="$(
        env |
        sort |
        fzf --prompt='copy env> '
    )" || return

    print -rn -- "${value#*=}" | pbcopy
}

# Fuzzy SSH host selection function
fssh() {
    local host

    host="$(
        {
            awk '
                tolower($1) == "host" {
                    for (i = 2; i <= NF; i++) {
                        if ($i !~ /[*?!]/) print $i
                    }
                }
            ' "$HOME/.ssh/config" 2>/dev/null

            awk '{print $1}' "$HOME/.ssh/known_hosts" 2>/dev/null |
            sed 's/,.*//'
        } |
        sort -u |
        fzf --prompt='ssh> '
    )" || return

    ssh "$host"
}

# Fuzzy serial device selection function
fserial() {
    local device

    case "$OSTYPE" in
        darwin*)
            device="$(
                printf '%s\n' /dev/cu.* 2>/dev/null |
                fzf --prompt='serial> '
            )"
            ;;
        linux*)
            device="$(
                {
                    printf '%s\n' /dev/ttyACM* /dev/ttyUSB* 2>/dev/null
                    find /dev/serial/by-id -type l 2>/dev/null
                } |
                sort -u |
                fzf \
                    --prompt='serial> ' \
                    --preview='udevadm info --query=property --name={} 2>/dev/null'
            )"
            ;;
        *)
            print -u2 "Unsupported platform: $OSTYPE"
            return 1
            ;;
    esac

    [[ -n "$device" ]] || return

    tio "$device"
}

# Fuzzy environment variable name selection function
fenvn() {
    local variable

    variable="$(
        envn |
        fzf \
            --prompt='env> ' \
            --preview='sh -c '\''printf "%s=%s\n" "$1" "$(printenv "$1")"'\'' sh {}'
    )" || return

    print -r -- "$variable"
}

# Fuzzy environment variable unset function
funset() {
    local variable

    variable="$(
        envn |
        fzf \
            --prompt='unset> ' \
            --preview='sh -c '\''printf "%s=%s\n" "$1" "$(printenv "$1")"'\'' sh {}'
    )" || return

    unset "$variable"
}

# Fuzzy environment variable set function
fset() {
    local variable
    local value

    variable="$(
        envn |
        fzf \
            --prompt='set> ' \
            --preview='sh -c '\''printf "%s=%s\n" "$1" "$(printenv "$1")"'\'' sh {}'
    )" || return

    read -r "value?Enter value for $variable: "
    export "$variable=$value"
}

# Fuzzy PATH entry selection function
fpath() {
    local path_entry

    path_entry="$(
        print $PATH | tr ':' '\n' |
        fzf \
            --prompt='fpath> ' \
            --preview='ls -la {}'
    )" || return

    print -r -- "$path_entry"
}
