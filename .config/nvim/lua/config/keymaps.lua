-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
-- keymap("", "<Space>", "<Nop>", opts) -- not sure why is this used so often
keymap("n", "<leader>f", "<cmd>FzfLua files<CR>", opts)
keymap("n", "<leader>b", "<cmd>FzfLua buffers<CR>", opts)

vim.keymap.set("n", "<leader>gg", function()
  require("snacks").lazygit()
end, { desc = "Open Lazygit (Snacks)" })
