-- LazyVim's default conform config only covers lua/fish/sh; clangd's own
-- LSP-fallback formatting works but is slower/less predictable than
-- running the actual formatters directly, honoring .clang-format as-is.
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        c = { "clang-format" },
        cpp = { "clang-format" },
        python = { "ruff_format" },
      },
    },
  },
  {
    "mason.nvim",
    opts = { ensure_installed = { "clang-format" } },
  },
}
