-- Gruvbox remains plugin-owned for now. The shared Wombat palette drives the
-- terminal surface; a later editor pass will feed this plugin's overrides.
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
