# Fuzzy project workflow pickers.

fj() {
    has_command just || {
        print -u2 "just is not installed"
        return 1
    }

    local recipe

    recipe="$(
        just --summary |
        tr ' ' '\n' |
        sed '/^$/d' |
        fzf \
            --prompt='just> ' \
            --preview='just --show {}'
    )" || return

    just "$recipe"
}
