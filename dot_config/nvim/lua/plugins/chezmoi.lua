-- Dotfiles (chezmoi) workflow keymaps, mirroring the dotdiff/dotapply/
-- dotstatus zsh functions in env/chezmoi.zsh.
local source_dir = vim.env.CHEZMOI_SOURCE_DIR or (vim.env.HOME .. "/.local/share/chezmoi")

return {
  "folke/snacks.nvim",
  keys = {
    { "<leader>m", group = "dotfiles" },
    {
      "<leader>md",
      function() Snacks.terminal({ "chezmoi", "diff" }, { cwd = source_dir }) end,
      desc = "Chezmoi diff",
    },
    {
      "<leader>ma",
      function() Snacks.terminal({ "chezmoi", "apply", "-v" }, { cwd = source_dir }) end,
      desc = "Chezmoi apply",
    },
    {
      "<leader>ms",
      function() Snacks.terminal({ "chezmoi", "status" }, { cwd = source_dir }) end,
      desc = "Chezmoi status",
    },
  },
}
