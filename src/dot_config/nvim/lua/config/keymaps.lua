-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Escape insert mode without leaving home row
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Disable arrow keys to force hjkl
for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
  map({ "n", "i", "v" }, key, "<Nop>", { desc = "Disabled (use hjkl)" })
end

-- LazyVim's own defaults bind <C-h/j/k/l> to plain <C-w>h/j/k/l ("Go to
-- Left/Down/Up/Right Window") on the VeryLazy event, which loads *after*
-- vim-tmux-navigator's plugin-init nnoremap of the same keys — silently
-- replacing it, not stacking with it. Plain <C-w>h just moves between
-- vim's own splits and does nothing at a split edge; it never falls
-- through to tmux, so navigating out to an adjacent tmux pane stopped
-- working while navigating within nvim's own splits kept working (the
-- part <C-w>h still does). This file also loads on VeryLazy but after
-- LazyVim's own config, so re-asserting the plugin's commands here wins.
for key, dir in pairs({ h = "Left", j = "Down", k = "Up", l = "Right" }) do
  map("n", "<C-" .. key .. ">", "<cmd>TmuxNavigate" .. dir .. "<cr>", { desc = "Tmux Navigate " .. dir, silent = true })
end

-- Window resizing, hjkl-ergonomic. Plain Ctrl+hjkl is vim-tmux-navigator's
-- (split/pane navigation, both here and in dot_tmux.conf.tmpl) and
-- Alt+h/l is tmux's own window-switch (bind -n, intercepted at the tmux
-- client before nvim ever sees it). Ctrl+Alt was the first attempt at an
-- unclaimed combination, but iTerm2's legacy key encoding can't actually
-- tell Ctrl+Alt+h apart from a bare Ctrl+h preceded by a stray Esc byte —
-- it read as plain Ctrl+h and just navigated instead of resizing. Cmd
-- (reported as "Super" now that iTerm2's CSI u / Kitty-protocol reporting
-- is on — nvim's own docs call <D-...> "Command-key or 'super' key",
-- exactly this) is unclaimed at every level and unambiguous over that
-- protocol, so it doesn't have the same problem.
map("n", "<D-k>", "<cmd>resize +2<CR>", { desc = "Increase window height" })
map("n", "<D-j>", "<cmd>resize -2<CR>", { desc = "Decrease window height" })
map("n", "<D-h>", "<cmd>vertical resize -2<CR>", { desc = "Decrease window width" })
map("n", "<D-l>", "<cmd>vertical resize +2<CR>", { desc = "Increase window width" })
