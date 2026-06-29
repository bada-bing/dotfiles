vim.cmd([[au BufRead,BufNewFile *.jq setfiletype jq]])

-- Disable treesitter highlighting for markdown — Neovim 0.12 crashes on the
-- conceal_lines predicate in the markdown highlights query (nil node range).
-- Falls back to Vim's built-in regex syntax. Remove once nvim-treesitter fixes
-- the query (https://github.com/neovim/neovim/issues/39032).
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.treesitter.stop(ev.buf)
  end,
})

vim.api.nvim_create_augroup("AutoExercismTest", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*/exercism_jq/*.jq", "*/exercism_jq/*.bats", "*/exercism/jq/*.jq", "*/exercism/jq/*.bats", "*/exercism_go/*.go", "*/exercism/go/*.go" },
  command = "! (cd %:h && exercism test)",
  group = "AutoExercismTest",
})