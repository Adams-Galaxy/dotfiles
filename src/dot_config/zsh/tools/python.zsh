# Project Python entry point. uv owns the local .venv, selected interpreter,
# and lockfile; `p` never needs to mutate the calling shell through activation.
p() {
  uv run python "$@"
}
