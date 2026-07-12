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

-- gf follows Logseq [[wiki-links]] in KB buffers: [[page name]] opens
-- pages/page name.md (Logseq stores namespace '/' as '%2F' on disk).
-- Falls back to built-in gf when the cursor is not inside a wiki-link.
-- Opening a page that doesn't exist yet gives a new buffer, so saving it
-- creates the page — same as following a link to a new page in Logseq.
local logseq_kb = vim.fn.expand("~/Documents/Logseq/KB")

-- Journal links use Logseq's default title format, e.g. [[Jul 12th, 2026]],
-- and live at journals/2026_07_12.md. Returns nil for non-date link names.
local logseq_months = {
  Jan = "01", Feb = "02", Mar = "03", Apr = "04", May = "05", Jun = "06",
  Jul = "07", Aug = "08", Sep = "09", Oct = "10", Nov = "11", Dec = "12",
}

local function logseq_journal_path(name)
  local mon, day, year = name:match("^(%a+) (%d+)%a*, (%d+)$")
  if not (mon and logseq_months[mon]) then
    return nil
  end
  return string.format("%s/journals/%s_%s_%02d.md", logseq_kb, year, logseq_months[mon], tonumber(day))
end

local function follow_logseq_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local from = 1
  while true do
    local s, e, name = line:find("%[%[(.-)%]%]", from)
    if not s then
      break
    end
    if col >= s and col <= e then
      local path = logseq_journal_path(name)
      if not path then
        path = logseq_kb .. "/pages/" .. name:gsub("/", "%%2F") .. ".md"
      end
      vim.cmd.edit(vim.fn.fnameescape(path))
      return
    end
    from = e + 1
  end
  vim.cmd("normal! gf")
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = logseq_kb .. "/*.md",
  callback = function(ev)
    vim.keymap.set("n", "gf", follow_logseq_link, { buffer = ev.buf, desc = "Follow Logseq wiki-link" })
  end,
})

vim.api.nvim_create_augroup("AutoExercismTest", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*/exercism_jq/*.jq", "*/exercism_jq/*.bats", "*/exercism/jq/*.jq", "*/exercism/jq/*.bats", "*/exercism_go/*.go", "*/exercism/go/*.go" },
  command = "! (cd %:h && exercism test)",
  group = "AutoExercismTest",
})