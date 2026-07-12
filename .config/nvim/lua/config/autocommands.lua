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

-- gf follows Logseq [[wiki-links]] and ((block refs)) in KB buffers:
-- [[page name]] opens pages/page name.md (Logseq stores namespace '/' as
-- '%2F' on disk), ((uuid)) jumps to the block carrying that id:: property.
-- Falls back to built-in gf when the cursor is not on either.
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

-- ((uuid)) block refs resolve through the id:: property Logseq writes under
-- the referenced block; find it with ripgrep and jump to that file/line.
local function logseq_follow_block_ref(line, col)
  local from = 1
  while true do
    local s, e, uuid = line:find("%(%(([%x%-]+)%)%)", from)
    if not s then
      return false
    end
    if col >= s and col <= e then
      local hits = vim.fn.systemlist({ "rg", "--vimgrep", "--fixed-strings", "id:: " .. uuid, logseq_kb })
      if #hits == 0 then
        vim.notify("block ref not found: " .. uuid, vim.log.levels.WARN)
      else
        local file, lnum = hits[1]:match("^(.-):(%d+):")
        vim.cmd.edit(vim.fn.fnameescape(file))
        vim.api.nvim_win_set_cursor(0, { tonumber(lnum), 0 })
      end
      return true
    end
    from = e + 1
  end
end

local function follow_logseq_link()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  if logseq_follow_block_ref(line, col) then
    return
  end
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

-- Linked references: quickfix list of every block in the KB linking to the
-- current page. Journal pages are referenced by their date title, so map the
-- filename back to e.g. "Jul 12th, 2026" before searching.
local logseq_month_names = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

local function logseq_page_title(path)
  local y, m, d = path:match("/journals/(%d+)_(%d+)_(%d+)%.md$")
  if y then
    d = tonumber(d)
    local suffix = ({ "st", "nd", "rd" })[d % 10]
    if not suffix or (d % 100 >= 11 and d % 100 <= 13) then
      suffix = "th"
    end
    return string.format("%s %d%s, %s", logseq_month_names[tonumber(m)], d, suffix, y)
  end
  local name = path:match("([^/]+)%.md$")
  return name and name:gsub("%%2F", "/") or nil
end

local function logseq_backlinks()
  local title = logseq_page_title(vim.api.nvim_buf_get_name(0))
  if not title then
    return
  end
  local link = "[[" .. title .. "]]"
  local hits = vim.fn.systemlist({ "rg", "--vimgrep", "--fixed-strings", link, logseq_kb })
  if #hits == 0 then
    vim.notify("no linked references to " .. link)
    return
  end
  vim.fn.setqflist({}, " ", { title = "Linked references to " .. link, efm = "%f:%l:%c:%m", lines = hits })
  vim.cmd.copen()
end

-- Locate the Logseq block containing the given line: returns the block's
-- first line number, its bullet indent, and its id:: uuid if it has one.
local function logseq_block_at(lines, lnum)
  local start
  for i = lnum, 1, -1 do
    if lines[i]:match("^%s*%-%s") or lines[i]:match("^%s*%-$") then
      start = i
      break
    end
  end
  if not start then
    return nil
  end
  local indent = lines[start]:match("^(%s*)%-")
  for i = start + 1, #lines do
    local l = lines[i]
    if l:match("^%s*%-%s") or #l:match("^%s*") <= #indent then
      break
    end
    local uuid = l:match("^%s*id::%s*([%x%-]+)%s*$")
    if uuid then
      return start, indent, uuid
    end
  end
  return start, indent, nil
end

-- Yank a ((block-ref)) for the block under the cursor, minting an id::
-- property (written exactly as Logseq would) when the block has none yet.
local function logseq_yank_block_ref()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local start, indent, uuid = logseq_block_at(lines, lnum)
  if not start then
    vim.notify("no block found at cursor", vim.log.levels.WARN)
    return
  end
  if not uuid then
    uuid = vim.fn.system("uuidgen"):gsub("%s+", ""):lower()
    vim.api.nvim_buf_set_lines(0, start, start, false, { indent .. "  id:: " .. uuid })
  end
  local ref = "((" .. uuid .. "))"
  vim.fn.setreg("+", ref)
  vim.fn.setreg('"', ref)
  vim.notify("yanked " .. ref)
end

-- gx opens the thing under the cursor in the Logseq app (the inverse of gf):
-- ((uuid)) -> that block, [[link]] -> that page, plain URL -> browser as
-- usual, anything else -> the current page, deep-linked to the cursor's
-- block when it carries an id:: property.
local function logseq_open_in_app()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local graph = vim.fn.fnamemodify(logseq_kb, ":t")

  local function url_encode(s)
    return (s:gsub("[^%w%-%._~]", function(c)
      return string.format("%%%02X", string.byte(c))
    end))
  end

  local target
  local from = 1
  while not target do
    local s, e, uuid = line:find("%(%(([%x%-]+)%)%)", from)
    if not s then
      break
    end
    if col >= s and col <= e then
      target = "block-id=" .. uuid
    end
    from = e + 1
  end
  from = 1
  while not target do
    local s, e, name = line:find("%[%[(.-)%]%]", from)
    if not s then
      break
    end
    if col >= s and col <= e then
      target = "page=" .. url_encode(name)
    end
    from = e + 1
  end
  if not target then
    local cfile = vim.fn.expand("<cfile>")
    if cfile:match("^https?://") then
      vim.ui.open(cfile)
      return
    end
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local _, _, uuid = logseq_block_at(lines, vim.api.nvim_win_get_cursor(0)[1])
    if uuid then
      target = "block-id=" .. uuid
    else
      local title = logseq_page_title(vim.api.nvim_buf_get_name(0))
      if not title then
        return
      end
      target = "page=" .. url_encode(title)
    end
  end
  vim.ui.open("logseq://graph/" .. graph .. "?" .. target)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = logseq_kb .. "/*.md",
  callback = function(ev)
    vim.keymap.set("n", "gf", follow_logseq_link, { buffer = ev.buf, desc = "Follow Logseq wiki-link" })
    vim.keymap.set("n", "gx", logseq_open_in_app, { buffer = ev.buf, desc = "Open in Logseq app" })
    vim.keymap.set("n", "<leader>lr", logseq_backlinks, { buffer = ev.buf, desc = "Logseq linked references" })
    vim.keymap.set("n", "<leader>ly", logseq_yank_block_ref, { buffer = ev.buf, desc = "Yank Logseq block ref" })
  end,
})

vim.api.nvim_create_augroup("AutoExercismTest", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*/exercism_jq/*.jq", "*/exercism_jq/*.bats", "*/exercism/jq/*.jq", "*/exercism/jq/*.bats", "*/exercism_go/*.go", "*/exercism/go/*.go" },
  command = "! (cd %:h && exercism test)",
  group = "AutoExercismTest",
})