require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "jqls", "jsonls", "gopls" },
})

require('lazydev').setup {}
