# Completion setup

fpath+=(~/.zfunc)

if command -v fzf >/dev/null 2>&1; then
	fzf_prefix=""

	if command -v brew >/dev/null 2>&1; then
		fzf_prefix="$(brew --prefix fzf 2>/dev/null || true)"
	fi

	for fzf_file in \
		"$fzf_prefix/shell/completion.zsh" \
		"$fzf_prefix/shell/key-bindings.zsh" \
		/usr/share/fzf/completion.zsh \
		/usr/share/fzf/key-bindings.zsh \
		/usr/share/doc/fzf/examples/completion.zsh \
		/usr/share/doc/fzf/examples/key-bindings.zsh; do
		if [[ -f "$fzf_file" ]]; then
			source "$fzf_file"
		fi
	done

	if command -v fd >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
		export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
	elif command -v fdfind >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fdfind --hidden --follow --exclude .git'
		export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
		export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
	fi
fi

if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
	fd() {
		fdfind "$@"
	}
fi

if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
	bat() {
		batcat "$@"
	}
fi
