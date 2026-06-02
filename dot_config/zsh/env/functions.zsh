# Shared shell functions

export GPIP_GITHUB_USER="Adams-Galaxy"
y() {
  local tmp
  local cwd
  tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  if [[ "$cwd" != "$PWD" && -d "$cwd" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

venv() {
  local dir="${1:-.}"
  local venv_path="$dir/.venv"

  if [[ ! -d "$venv_path" ]]; then
    echo "Creating virtual environment in $venv_path"
    python3 -m venv "$venv_path"
  fi

  source "$venv_path/bin/activate"
}
