require("mason").setup()
require("mason-lspconfig").setup()

-- After setting up mason-lspconfig you may set up servers via vim.lsp.config
vim.lsp.config.lua_ls = {}

-- Neodev setup for Lua environment
-- require("lazydev").setup({
--   library = { plugins = { "nvim-treesitter", "nvim-lspconfig" }, types = true },
-- })
require('lazydev').setup {}

-- Configure NeoVim to recognize jq files as jq filetype
vim.cmd([[au BufRead,BufNewFile *.jq setfiletype jq]])
vim.lsp.config.jqls = {}
vim.lsp.config.jsonls = {}

vim.lsp.config.gopls = {}
-- ...
