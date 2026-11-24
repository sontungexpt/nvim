-- ------------------------------------------------- Editing -------------------------------------------------
-- Text editing enhancement plugins.
-- Mission: Improve the core editing experience (commenting code, indentation guides, color picker).
return {
	-- Support comment
	-- {
	-- 	"numToStr/Comment.nvim",
	-- 	keys = {
	-- 		{ "gcc", mode = "n", desc = "Toggle line comment" },
	-- 		{ "gbc", mode = "n", desc = "Toggle block comment" },
	-- 		{ "gc", mode = { "n", "o", "v" }, desc = "Comment motion" },
	-- 		{ "gb", mode = { "n", "o", "v" }, desc = "Block comment motion" },
	-- 	},
	-- 	dependencies = {
	-- 		{
	-- 			"JoosepAlviste/nvim-ts-context-commentstring",
	-- 			dependencies = { "nvim-treesitter/nvim-treesitter" },
	-- 			opts = {
	-- 				enable_autocmd = false,
	-- 				config = {
	-- 					lua = "-- %s",
	-- 				},
	-- 			},
	-- 		},
	-- 	},
	-- 	opts = function()
	-- 		return {
	-- 			ignore = "^$",
	-- 			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
	-- 		}
	-- 	end,
	-- },

	{
		"folke/ts-comments.nvim",
		event = "User FirstKeyReady",
		opts = {},
	},

	-- Auto indent
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "User FirstFileReady",
		main = "ibl",
		dependencies = {
			"HiPhish/rainbow-delimiters.nvim",
		},
		opts = function()
			local hooks = require("ibl.hooks")
			hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
			return {
				indent = {
					char = "│",
				},
				scope = {
					char = "│",
					show_start = false,
				},
				exclude = {
					filetypes = { "alpha", "dashboard", "Trouble", "lazy", "NvimTree", "mason" },
				},
			}
		end,
	},

	-- Color picker: pick a color and insert its value into the buffer
	{
		"uga-rosa/ccc.nvim",
		cmd = "CccPick",
		opts = {},
	},

	{
		dir = "/home/stilux/Data/workspace/neovim-plugins/witch-colors",
		-- "brenoprata10/nvim-highlight-colors",
		-- event = "User FirstFileReady",
		lazy = false,
		opts = {},
	},
	-- Color hex highlighting: shows background color for color codes (#RRGGBB, rgb(), etc.)
	-- {
	-- 	dir = "/home/stilux/Data/workspace/neovim-plugins/nvim-highlight-colors",
	-- 	-- "brenoprata10/nvim-highlight-colors",
	-- 	event = "User FirstFileReady",
	-- 	opts = {},
	-- },

	-- Flash: enhanced search and motion with labels (s, S, f, F, t, T, etc.)
	-- {
	--   "folke/flash.nvim",
	--   event = "VeryLazy",
	--   ---@type Flash.Config
	--   opts = {},
	--   keys = {
	--     { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
	--     { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
	--     { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
	--     { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
	--     { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
	--   },
	-- },
}
