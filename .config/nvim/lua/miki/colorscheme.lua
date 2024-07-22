local colorscheme = "rose-pine" -- colorscheme first needs to be installed as a plugin in plugins.lua

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme) -- vim.cmd "colorscheme rose-pine"
if not status_ok then
  vim.notify("What is wrong," .. _)
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end
