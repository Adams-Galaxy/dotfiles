#!/usr/bin/env sh
# Lint pass across the dotfiles repo: shell/zsh syntax, Lua syntax,
# TOML/JSON validity, template rendering, and the package manifest shape.
# Run before `chezmoi apply` to catch mistakes early.
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$repo_dir"

pass=0
fail=0
skip=0

have_command() {
  command -v "$1" >/dev/null 2>&1
}

ok() {
  printf '  ok    %s\n' "$1"
  pass=$((pass + 1))
}

bad() {
  printf '  FAIL  %s\n' "$1"
  fail=$((fail + 1))
}

skipped() {
  printf '  skip  %s (%s)\n' "$1" "$2"
  skip=$((skip + 1))
}

check_sh() {
  file="$1"
  if sh -n "$file" 2>/tmp/check_sh_err; then
    ok "$file"
  else
    bad "$file"
    sed 's/^/        /' /tmp/check_sh_err
  fi
  rm -f /tmp/check_sh_err
}

check_zsh() {
  file="$1"
  if ! have_command zsh; then
    skipped "$file" "zsh not installed"
    return
  fi
  if zsh -n "$file" 2>/tmp/check_zsh_err; then
    ok "$file"
  else
    bad "$file"
    sed 's/^/        /' /tmp/check_zsh_err
  fi
  rm -f /tmp/check_zsh_err
}

check_rendered_sh() {
  file="$1"
  if ! have_command chezmoi; then
    skipped "$file" "chezmoi not installed"
    return
  fi
  tmp="$(mktemp)"
  if chezmoi execute-template <"$file" >"$tmp" 2>/tmp/check_render_err && sh -n "$tmp" 2>>/tmp/check_render_err; then
    ok "$file (rendered)"
  else
    bad "$file (rendered)"
    sed 's/^/        /' /tmp/check_render_err
  fi
  rm -f "$tmp" /tmp/check_render_err
}

check_rendered_zsh() {
  file="$1"
  if ! have_command chezmoi || ! have_command zsh; then
    skipped "$file" "chezmoi or zsh not installed"
    return
  fi
  tmp="$(mktemp)"
  if chezmoi execute-template <"$file" >"$tmp" 2>/tmp/check_render_err && zsh -n "$tmp" 2>>/tmp/check_render_err; then
    ok "$file (rendered)"
  else
    bad "$file (rendered)"
    sed 's/^/        /' /tmp/check_render_err
  fi
  rm -f "$tmp" /tmp/check_render_err
}

check_rendered_tmux() {
  file="$1"
  if ! have_command chezmoi || ! have_command tmux; then
    skipped "$file" "chezmoi or tmux not installed"
    return
  fi
  tmp="$(mktemp)"
  sock="check-tmux-$$"
  if chezmoi execute-template <"$file" >"$tmp" 2>/tmp/check_render_err \
    && tmux -L "$sock" -f "$tmp" new-session -d 2>>/tmp/check_render_err; then
    ok "$file (rendered)"
  else
    bad "$file (rendered)"
    sed 's/^/        /' /tmp/check_render_err
  fi
  tmux -L "$sock" kill-server >/dev/null 2>&1
  rm -f "$tmp" /tmp/check_render_err
}

check_rendered_toml() {
  file="$1"
  if ! have_command chezmoi || ! have_command python3; then
    skipped "$file" "chezmoi or python3 not installed"
    return
  fi
  tmp="$(mktemp)"
  if chezmoi execute-template <"$file" >"$tmp" 2>/tmp/check_render_err \
    && python3 -c "import tomllib,sys; tomllib.load(open(sys.argv[1],'rb'))" "$tmp" 2>>/tmp/check_render_err; then
    ok "$file (rendered)"
  else
    bad "$file (rendered)"
    sed 's/^/        /' /tmp/check_render_err
  fi
  rm -f "$tmp" /tmp/check_render_err
}

check_lua() {
  file="$1"
  if ! have_command luac; then
    skipped "$file" "luac not installed"
    return
  fi
  if luac -p "$file" 2>/tmp/check_lua_err; then
    ok "$file"
  else
    bad "$file"
    sed 's/^/        /' /tmp/check_lua_err
  fi
  rm -f /tmp/check_lua_err
}

check_fastfetch() {
  file="$1"
  if ! have_command fastfetch || ! have_command chezmoi; then
    skipped "$file" "fastfetch or chezmoi not installed"
    return
  fi
  # Rendered first since these are chezmoi templates (theme colors) now,
  # not plain JSONC - fastfetch would otherwise choke on the literal
  # {{ ... }} actions. Needs a .jsonc suffix - fastfetch -c refuses an
  # extensionless path ("couldn't find config").
  tmp="$(mktemp "${TMPDIR:-/tmp}/check-fastfetch-XXXXXX.jsonc")"
  # Runs the real parser rather than a generic JSON/JSONC linter, since
  # fastfetch's config is JSONC (comments) with its own module/format
  # schema a generic validator wouldn't catch mistakes in anyway —
  # --logo none/--pipe true keep this to a syntax+schema check, no ANSI
  # noise in the output either way.
  if chezmoi execute-template <"$file" >"$tmp" 2>/tmp/check_fastfetch_err \
    && fastfetch -c "$tmp" --logo none --pipe true >/dev/null 2>>/tmp/check_fastfetch_err; then
    ok "$file (rendered)"
  else
    bad "$file (rendered)"
    sed 's/^/        /' /tmp/check_fastfetch_err
  fi
  rm -f "$tmp" /tmp/check_fastfetch_err
}

check_toml() {
  file="$1"
  if ! have_command python3; then
    skipped "$file" "python3 not installed"
    return
  fi
  if python3 -c "import tomllib,sys; tomllib.load(open(sys.argv[1],'rb'))" "$file" 2>/tmp/check_toml_err; then
    ok "$file"
  else
    bad "$file"
    sed 's/^/        /' /tmp/check_toml_err
  fi
  rm -f /tmp/check_toml_err
}

check_json() {
  file="$1"
  if ! have_command python3; then
    skipped "$file" "python3 not installed"
    return
  fi
  if python3 -m json.tool "$file" >/dev/null 2>/tmp/check_json_err; then
    ok "$file"
  else
    bad "$file"
    sed 's/^/        /' /tmp/check_json_err
  fi
  rm -f /tmp/check_json_err
}

echo "== shell scripts (sh -n) =="
for f in scripts/*.sh; do
  [ -f "$f" ] || continue
  check_sh "$f"
done

echo
echo "== templated shell scripts (rendered, sh -n) =="
for f in run_once_*.sh.tmpl; do
  [ -f "$f" ] || continue
  check_rendered_sh "$f"
done

echo
echo "== zsh files (zsh -n) =="
file_list="$(mktemp)"
find dot_config/zsh -type f -name "*.zsh" -print | sort >"$file_list"
while IFS= read -r f; do
  check_zsh "$f"
done <"$file_list"

echo
echo "== templated zsh files (rendered, zsh -n) =="
find dot_config/zsh -type f -name "*.zsh.tmpl" -print | sort >"$file_list"
while IFS= read -r f; do
  check_rendered_zsh "$f"
done <"$file_list"
[ -f dot_zshrc.tmpl ] && check_rendered_zsh dot_zshrc.tmpl

echo
echo "== templated tmux config (rendered, tmux -f) =="
[ -f dot_tmux.conf.tmpl ] && check_rendered_tmux dot_tmux.conf.tmpl

echo
echo "== Lua files (luac -p) =="
find dot_config/nvim dot_config/wezterm -type f -name "*.lua" -print | sort >"$file_list"
while IFS= read -r f; do
  check_lua "$f"
done <"$file_list"

echo
echo "== fastfetch config =="
[ -f dot_config/fastfetch/config.jsonc.tmpl ] && check_fastfetch dot_config/fastfetch/config.jsonc.tmpl
[ -f dot_config/fastfetch/config-compact.jsonc.tmpl ] && check_fastfetch dot_config/fastfetch/config-compact.jsonc.tmpl

echo
echo "== TOML files =="
find . -type f -name "*.toml" -not -path "*/.git/*" -print | sort >"$file_list"
while IFS= read -r f; do
  check_toml "$f"
done <"$file_list"

echo
echo "== templated TOML files (rendered) =="
find . -type f -name "*.toml.tmpl" -not -path "*/.git/*" -print | sort >"$file_list"
while IFS= read -r f; do
  case "$f" in
    ./.chezmoi.toml.tmpl)
      # Uses promptString, only available inside `chezmoi init`'s own
      # execution context, not the generic `execute-template` command
      # this script uses everywhere else - can't render it here.
      skipped "$f" "uses promptString, only valid during chezmoi init"
      ;;
    *)
      check_rendered_toml "$f"
      ;;
  esac
done <"$file_list"

echo
echo "== JSON files =="
find . -type f -name "*.json" -not -path "*/.git/*" -print | sort >"$file_list"
while IFS= read -r f; do
  check_json "$f"
done <"$file_list"
rm -f "$file_list"

echo
echo "== package manifest shape (scripts/packages.conf) =="
manifest="scripts/packages.conf"
if [ -f "$manifest" ]; then
  bad_rows="$(
    awk '
      /^[[:space:]]*#/ { next }
      NF == 0 { next }
      NF != 3 { print NR": expected 3 fields, got "NF; next }
      $2 !~ /(^|,)(macos|linux)(,|$)/ { print NR": profiles field has no macos/linux tag: "$2 }
    ' "$manifest"
  )"
  if [ -z "$bad_rows" ]; then
    ok "$manifest"
  else
    bad "$manifest"
    printf '%s\n' "$bad_rows" | sed 's/^/        /'
  fi
else
  skipped "$manifest" "not found"
fi

echo
echo "== chezmoi dry-run (full template render) =="
if have_command chezmoi; then
  if chezmoi apply --dry-run --verbose >/tmp/check_dryrun.log 2>&1; then
    ok "chezmoi apply --dry-run"
  else
    bad "chezmoi apply --dry-run"
    sed 's/^/        /' /tmp/check_dryrun.log
  fi
  rm -f /tmp/check_dryrun.log
else
  skipped "chezmoi apply --dry-run" "chezmoi not installed"
fi

echo
printf 'Results: %d passed, %d failed, %d skipped\n' "$pass" "$fail" "$skip"

[ "$fail" -eq 0 ]
