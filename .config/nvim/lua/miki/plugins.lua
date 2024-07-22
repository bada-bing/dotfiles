local fn = vim.fn

-- Automatically install packer
-- data location: /Users/miki/.config/local/share/nvim/site/... try echo stdpath("data")
local install_path = fn.stdpath "data" .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
  PACKER_BOOTSTRAP = fn.system {
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  }
  print "Installing packer. Close and reopen Neovim..."
  vim.cmd [[packadd packer.nvim]]
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd [[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
  return
end

-- Have packer use a popup window
packer.init {
  display = {
    open_fn = function()
      return require("packer.util").float { border = "rounded" }
    end,
  },
}

-- Install your plugins here
return packer.startup(function(use)
  -- Essential Plugins
  use "wbthomason/packer.nvim" -- Have packer manage itself
  use "nvim-lua/popup.nvim" -- An implementation of the Popup API from vim in Neovim
  use "nvim-lua/plenary.nvim" -- Useful lua functions used by lots of plugins

  -- Colorschemes
  -- use 'folke/tokyonight.nvim'
  use({ 'rose-pine/neovim', as = 'rose-pine' })


  -- Completions - cmp plugins
  use "hrsh7th/nvim-cmp"      -- The completion plugin
  use "hrsh7th/cmp-buffer"    -- words from the current buffer completions
  use "hrsh7th/cmp-path"      -- complete files completions
  use "hrsh7th/cmp-cmdline"   -- cmdline completions
  use "hrsh7th/cmp-nvim-lua"  -- lua neovim development completions
  use "hrsh7th/cmp-nvim-lsp"  -- lsp completions
  
  use "L3MON4D3/LuaSnip"         -- snippet engine
  use "saadparwaiz1/cmp_luasnip" -- snippet completions
  
  -- Find Files (Telescope) 
  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.0',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  
  -- LSP
  use "neovim/nvim-lspconfig" -- enable LSP
  use "williamboman/mason.nvim" -- simple to use language server installer
  use "williamboman/mason-lspconfig.nvim" -- simplp to use language server installer  

  -- TreeSitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }
  
  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if PACKER_BOOTSTRAP then
    require("packer").sync()
  end
end)
