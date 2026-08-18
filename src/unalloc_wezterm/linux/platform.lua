-- A conventional Linux fallback keeps the shared configuration buildable on
-- distributions that are deliberately not assigned to a machine layer yet.
return {
  default_prog = { "/bin/zsh", "-l" },
}
