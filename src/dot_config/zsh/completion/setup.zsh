# Native fzf bindings and completion prerequisites.

fpath+=("$HOME/.zfunc" "$DOTFILES/completions")

if command -v fzf >/dev/null 2>&1; then
	# `brew --prefix fzf` is a subprocess on every startup; cache the answer
	# and refresh it only if the fzf binary has changed since.
	fzf_prefix=""
	fzf_prefix_cache="$ZSH_CACHE_DIR/fzf-prefix"

	if [[ -f "$fzf_prefix_cache" && ! "${commands[fzf]}" -nt "$fzf_prefix_cache" ]]; then
		fzf_prefix="$(<"$fzf_prefix_cache")"
	elif command -v brew >/dev/null 2>&1; then
		fzf_prefix="$(brew --prefix fzf 2>/dev/null || true)"
		if [[ -n "$fzf_prefix" ]]; then
			[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"
			print -r -- "$fzf_prefix" > "$fzf_prefix_cache"
		fi
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
