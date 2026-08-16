# Python conveniences.

alias p="python3"

venv() {
  local dir="${1:-.}"
  local venv_path="$dir/.venv"

  if [[ ! -d "$venv_path" ]]; then
    print "Creating virtual environment in $venv_path"
    python3 -m venv "$venv_path"
  fi

  source "$venv_path/bin/activate"
}
