-- This file is consumed by Windows-native WezTerm. Its normal first pane is
-- therefore wsl.exe, while deployment remains in WSL's usual config location.
return {
  default_prog = { "wsl.exe", "--cd", "~" },
}
