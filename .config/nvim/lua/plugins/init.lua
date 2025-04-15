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
				-- optional for icon support
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
				"folke/noice.nvim",
				event = "VeryLazy",
				opts = {
						-- add any options here
				},
				dependencies = {
						-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
						"MunifTanjim/nui.nvim",
						-- OPTIONAL:
						--   `nvim-notify` is only needed, if you want to use the notification view.
						--   If not available, we use `mini` as the fallback
						"rcarriga/nvim-notify",
				}
		},
		{
				"folke/snacks.nvim",
				---@type snacks.Config
				opts = {
						indent = {
								-- your indent configuration comes here
								-- or leave it empty to use the default settings
								-- refer to the configuration section below
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
