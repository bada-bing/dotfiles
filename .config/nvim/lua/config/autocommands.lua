vim.api.nvim_create_augroup("AutoExercismTest", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
--   pattern = { "lasagna.jq", "test-lasagna.bats" },
  pattern = { "*/exercism_jq/*.jq", "*/exercism_jq/*.bats", "*/exercism/jq/*.jq", "*/exercism/jq/*.bats" },
  command = "! (cd %:h && exercism test)",
  group = "AutoExercismTest",
})

