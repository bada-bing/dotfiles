require("mason").setup()
require("mason-lspconfig").setup()

-- After setting up mason-lspconfig you may set up servers via lspconfig
require("lspconfig").lua_ls.setup {}

-- Neodev setup for Lua environment
-- require("lazydev").setup({
--   library = { plugins = { "nvim-treesitter", "nvim-lspconfig" }, types = true },
-- })
-- require("lazydev").setup() {} end
require('lazydev').setup {}

-- Configure NeoVim to recognize jq files as jq filetype
vim.cmd([[au BufRead,BufNewFile *.jq setfiletype jq]])
require("lspconfig").jqls.setup {}
require("lspconfig").jsonls.setup {}

require("lspconfig").gopls.setup {}
-- ...
