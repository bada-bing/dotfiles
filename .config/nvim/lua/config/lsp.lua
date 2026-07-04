vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "jqls", "jsonls", "gopls" },
})
