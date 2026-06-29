return {
		-- "folke/neodev.nvim",
		{
				"folke/lazydev.nvim",
				ft = "lua", -- only load on lua files
				opts = {
						library = {
								-- See the configuration section for more details
								-- Load luvit types when the `vim.uv` word is found
								{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
						},
				},
		},
		"folke/which-key.nvim",
		-- { "folke/neoconf.nvim", cmd = "Neoconf" },
		{
				'nvim-lualine/lualine.nvim',
				dependencies = { 'nvim-tree/nvim-web-devicons' }
		},
		{
				"ibhagwan/fzf-lua",
				dependencies = { "nvim-tree/nvim-web-devicons" },
				-- or if using mini.icons/mini.nvim
				-- dependencies = { "echasnovski/mini.icons" },
				opts = {}
		},
		{
				"folke/tokyonight.nvim",
				lazy = false,
				priority = 1000,
				opts = {
						transparent = true,
						styles = "transparent",
						floats = "transparent"
				},
		},
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"neovim/nvim-lspconfig",
		{
		  'nvim-treesitter/nvim-treesitter',
		  build = ':TSUpdate',  -- auto-update parsers after install
		  config = function()
			require('nvim-treesitter.configs').setup {
			  highlight = { enable = true },
			  indent = { enable = true },
			  ensure_installed = { "lua", "python", "javascript", "java", "typescript", "go", "bash", "json", "yaml", "toml", "markdown", "markdown_inline" },
			}
		  end
		},
		{
				"folke/snacks.nvim",
				---@type snacks.Config
				opts = {
						indent = {
								-- Disable treesitter-based scope detection — crashes in Neovim 0.12 on
								-- markdown files due to a nil node in the conceal_lines predicate
								-- (https://github.com/neovim/neovim/issues/39032). Falls back to
								-- indent-based scope detection which works correctly everywhere.
								scope = {
										treesitter = { enabled = false },
								},
						},
						lazygit = {}
				}
		},
		{
				'saghen/blink.cmp',
				-- optional: provides snippets for the snippet source
				-- dependencies = { 'rafamadriz/friendly-snippets' },

				-- use a release tag to download pre-built binaries
				version = '1.*',
				-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
				-- build = 'cargo build --release',

				---@module 'blink.cmp'
				---@type blink.cmp.Config
				opts = {
						-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
						-- 'super-tab' for mappings similar to vscode (tab to accept)
						-- 'enter' for enter to accept
						-- 'none' for no mappings
						--
						-- All presets have the following mappings:
						-- C-space: Open menu or open docs if already open
						-- C-n/C-p or Up/Down: Select next/previous item
						-- C-e: Hide menu
						-- C-k: Toggle signature help (if signature.enabled = true)
						--
						-- See :h blink-cmp-config-keymap for defining your own keymap
						keymap = { preset = 'default' },

						appearance = {
								-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
								-- Adjusts spacing to ensure icons are aligned
								nerd_font_variant = 'mono'
						},

						-- (Default) Only show the documentation popup when manually triggered
						completion = { documentation = { auto_show = false } },

						-- Default list of enabled providers defined so that you can extend it
						-- elsewhere in your config, without redefining it, due to `opts_extend`
						sources = {
								default = { 'lsp', 'path', 'snippets', 'buffer' },
						},

						-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
						-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
						-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
						--
						-- See the fuzzy documentation for more information
						fuzzy = { implementation = "prefer_rust_with_warning" }
				},
				opts_extend = { "sources.default" }
		}
}
