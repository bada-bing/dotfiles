vim.cmd([[au BufRead,BufNewFile *.jq setfiletype jq]])

vim.api.nvim_create_augroup("AutoExercismTest", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*/exercism_jq/*.jq", "*/exercism_jq/*.bats", "*/exercism/jq/*.jq", "*/exercism/jq/*.bats", "*/exercism_go/*.go", "*/exercism/go/*.go" },
  command = "! (cd %:h && exercism test)",
  group = "AutoExercismTest",
})