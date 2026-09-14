# Make cool ascii art with figlet and copy it to the clipboard
funny() {
    local art
    art="$(figlet -f "ANSI Shadow" "$@" | sed '${/^[[:space:]]*$/d;}')"
    print -r -- "\`\`\`${art}\`\`\`" | clip -q
    print ${art}
}
