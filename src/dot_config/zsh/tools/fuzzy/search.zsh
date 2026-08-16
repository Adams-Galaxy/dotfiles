# Fuzzy content search.

frg() {
    local selected
    local query="${*:-}"

    selected="$(
        FZF_DEFAULT_COMMAND="rg \
            --column \
            --line-number \
            --no-heading \
            --color=always \
            --smart-case \
            -- '$query' || true" \
        fzf \
            --ansi \
            --disabled \
            --query="$query" \
            --prompt='rg> ' \
            --delimiter=: \
            --bind="change:reload:rg \
                --column \
                --line-number \
                --no-heading \
                --color=always \
                --smart-case \
                -- {q} || true" \
            --preview='bat \
                --color=always \
                --style=numbers \
                --highlight-line {2} \
                {1}' \
            --preview-window='right,60%,border-left,+{2}+3/3'
    )" || return

    local file="${selected%%:*}"
    local rest="${selected#*:}"
    local line="${rest%%:*}"

    "${EDITOR:-nvim}" "+${line}" "$file"
}
