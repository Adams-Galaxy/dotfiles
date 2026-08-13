-- Zephyr/west projects cross-compile for an embedded target; without
-- --query-driver clangd assumes the host toolchain for builtin includes
-- and macros, producing pervasive false errors on target-specific code.
-- --query-driver is just an allowlist glob: it's a no-op for any project
-- whose compile_commands.json doesn't reference a matching compiler path,
-- so this is safe to set unconditionally rather than needing to detect
-- Zephyr projects at runtime.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
            "--query-driver=" .. vim.fn.expand("~/.zephyr_ide/toolchains") .. "/**/*",
          },
        },
      },
    },
  },
}
