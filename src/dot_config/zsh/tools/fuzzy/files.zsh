# Fuzzy filesystem and directory pickers.

fe() {
    local file

    file="$(
        fd \
            --type f \
            --hidden \
            --follow \
            --exclude .git |
        fzf \
            --prompt='edit> ' \
            --preview='bat --color=always --style=numbers --line-range=:500 {}'
    )" || return

    "${EDITOR:-nvim}" "$file"
}

fz() {
    local dir

    dir="$(
        zoxide query --list --score |
        fzf \
            --prompt='zoxide> ' \
            --nth=2.. \
            --tac \
            --preview='
                path=$(echo {} | cut -d" " -f2-)
                eza --tree --level=2 --color=always "$path" 2>/dev/null ||
                ls -la "$path"
            ' |
        cut -d' ' -f2-
    )" || return

    cd "$dir"
}
