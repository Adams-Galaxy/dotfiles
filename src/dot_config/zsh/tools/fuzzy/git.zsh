# Fuzzy Git pickers.

# Fuzzy git branch switch function
fgb() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        print -u2 "Not inside a Git repository"
        return 1
    }

    local branch

    branch="$(
        git branch \
            --all \
            --format='%(refname:short)' |
        sed 's#^origin/##' |
        awk '!seen[$0]++' |
        fzf \
            --prompt='branch> ' \
            --preview='git log \
                --color=always \
                --graph \
                --date=short \
                --pretty=format:"%C(auto)%h%d %s %C(black)%C(bold)%cr" \
                {} --'
    )" || return

    git switch "$branch"
}

# Fuzzy git branch delete function
fgbd() {
    local branch

    branch="$(
        git for-each-ref \
            --format='%(refname:short)' \
            refs/heads |
        grep -vx "$(git branch --show-current)" |
        fzf \
            --multi \
            --prompt='delete branches> ' \
            --preview='git log --color=always --oneline --decorate -20 {}'
    )" || return

    print -r -- "$branch" |
    while IFS= read -r selected; do
        git branch -d "$selected"
    done
}

# Fuzzy git log function
fgl() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        print -u2 "Not inside a Git repository"
        return 1
    }

    local commit

    commit="$(
        git log \
            --color=always \
            --format='%C(auto)%h %C(blue)%ad%Creset %C(auto)%d %s %C(dim white)[%an]%Creset' \
            --date=short |
        fzf \
            --ansi \
            --no-sort \
            --prompt='commit> ' \
            --preview='
                hash=$(echo {} | grep -oE "[0-9a-f]{7,}" | head -1)
                git show --color=always --stat --patch "$hash"
            ' |
        grep -oE '[0-9a-f]{7,}' |
        head -1
    )" || return

    git show "$commit"
}

# Fuzzy git file open function
fgf() {
    local file

    file="$(
        git ls-files |
        fzf \
            --preview='bat --color=always --style=numbers {}'
    )"

    [[ -n "$file" ]] && "${EDITOR:-nvim}" "$file"
}

# Fuzzy git status file open function
fgs() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        print -u2 "Not inside a Git repository"
        return 1
    }

    local file

    file="$(
        git status --short |
        fzf \
            --ansi \
            --prompt='changed> ' \
            --preview='
                file=$(echo {} | sed "s/^...//")
                git diff --color=always -- "$file"
                git diff --cached --color=always -- "$file"
            ' |
        sed 's/^...//'
    )" || return

    "${EDITOR:-nvim}" "$file"
}

# Fuzzy git stash show function
fgstash() {
    local stash

    stash="$(
        git stash list |
        fzf \
            --prompt='stash> ' \
            --preview='
                ref=$(echo {} | cut -d: -f1)
                git stash show --color=always --patch "$ref"
            ' |
        cut -d: -f1
    )" || return

    git stash show --patch "$stash"
}

# Fuzzy git stash apply function
fgstash-apply() {
    local stash

    stash="$(
        git stash list |
        fzf \
            --prompt='apply stash> ' \
            --preview='
                ref=$(echo {} | cut -d: -f1)
                git stash show --color=always --patch "$ref"
            ' |
        cut -d: -f1
    )" || return

    git stash apply "$stash"
}
