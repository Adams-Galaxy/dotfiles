# Optional splash helper

splash() {
  if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
  else
    print "fastfetch is not installed"
  fi
}
