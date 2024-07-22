local status_ok, _ = pcall(require, "lspconfig")
if not status_ok then
  return
end

require "miki.lsp.mason"
require("miki.lsp.handlers").setup()
require "miki.lsp.null-ls"
