-- Gruvbox dark-hard: the same hex palette as tmux (gruvbox-tmux) and
-- starship's gruvbox_dark table, so all three stay pixel-identical.
return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "hard",
      terminal_colors = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
