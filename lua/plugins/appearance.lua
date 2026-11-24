-- ------------------------------------------------- Appearance -------------------------------------------------
-- Theme, colorscheme, statusline, and visual styling plugins.
-- Mission: Control how the editor looks (themes, statusline).
return {
	{
		"sontungexpt/witch-line",
		lazy = false,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			auto_theme = false,
		},
	},
	{
		"sontungexpt/witch",
		-- dir = "/home/stilux/Data/workspace/neovim-plugins/witch",
		priority = 1000,
		lazy = false,
		opts = {},
	},
}
