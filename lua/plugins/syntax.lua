local vim = vim

-- ---------------------------------------------------- Syntax ----------------------------------------------------
-- Tree-sitter syntax highlighting, indentation, folds, and markdown rendering.

return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"HiPhish/rainbow-delimiters.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		build = ":TSUpdate",
		event = "User FileLazyLoaded",
		cmd = { "TSUpdate", "TSInstall", "TSInstallFromGrammar", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
		opts = {
			-- Single list of tree-sitter languages ensured to be installed
			-- This should use for some parser that can not detect by filetype
			ensure_installed = {
				-- Core / Neovim
				"lua",
				"luadoc",
				"vim",
				"vimdoc",
				"diff",
				"regex",
				"printf",
				"query",
				"markdown",
				"markdown_inline",
			},
		},
		config = function(_, opts)
			local TS = require("nvim-treesitter")

			-- setup treesitter once
			TS.setup(opts)

			-- ------------------------------------------------------------------
			-- Ensure tree-sitter CLI is available before any parser install.
			-- If missing (e.g. user deleted it), try to install via mason.
			-- ------------------------------------------------------------------
			local function ensure_ts_cli(cb)
				if vim.fn.executable("tree-sitter") == 1 then return cb(true) end

				local notify = require("utils.notify")
				local ok, mason = pcall(require, "mason-registry")
				if not ok then
					notify.warn("mason.nvim is required to auto-install tree-sitter-cli")
					return cb(false)
				end

				mason.refresh(function()
					local pkg = mason.get_package("tree-sitter-cli")
					if pkg:is_installed() then return cb(true) end
					notify.info("Installing tree-sitter-cli via mason...")
					pkg:install(
						nil,
						vim.schedule_wrap(function(success)
							if success then
								notify.info("tree-sitter-cli installed.")
								cb(true)
							else
								notify.warn("Failed to install tree-sitter-cli via mason.")
								cb(false)
							end
						end)
					)
				end)
			end

			-- install list is the single ensured_install table
			local ensure_installed = opts.ensure_installed or {}

			-- compute installed parser set once (single filesystem scan)
			local installed = {}
			for _, lang in ipairs(TS.get_installed()) do
				installed[lang] = true
			end

			-- ------------------------------------------------------------------
			-- Install missing parsers; only mark installed after async :await succeeds.
			-- ------------------------------------------------------------------
			local function install_missing(langs, summary)
				local todo = {}
				for _, lang in ipairs(langs) do
					if not installed[lang] then todo[#todo + 1] = lang end
				end
				if #todo == 0 then return end

				local notify = require("utils.notify")
				ensure_ts_cli(function(ok)
					if not ok then
						notify.warn("Skipping parser install: tree-sitter-cli is unavailable")
						return
					end
					TS.install(todo, { summary = summary or true }):await(function()
						for _, lang in ipairs(todo) do
							installed[lang] = true
						end
						notify.info("Tree-sitter parsers installed: " .. table.concat(todo, ", "))
					end)
				end)
			end

			-- install any parsers from ensure_installed that are missing on startup
			install_missing(ensure_installed, true)

			local parsers = require("nvim-treesitter.parsers")
			-- cache filetype -> language mapping to avoid repeated get_lang calls
			local lang_cache = {}

			-- auto install treesitter language parser when opening a file whose
			-- parser is not yet installed, and enable highlighting/indentation
			-- (on-demand, mirrors LazyVim behavior)
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("__treesitter_auto_install__", { clear = true }),
				callback = function(ev)
					local ft = ev.match
					local lang = lang_cache[ft]
					if lang == nil then
						lang = vim.treesitter.language.get_lang(ft)
						lang_cache[ft] = lang
					end

					-- skip languages that have no tree-sitter parser (e.g. snacks_notif)
					if not lang or not parsers[lang] then return end

					-- install the parser on first use if it is not yet installed.
					-- We do NOT optimistically mark it installed; the :await callback
					-- below marks it only after the install actually succeeds.
					local start_treesitter = function()
						if not vim.treesitter.highlighter.active[ev.buf] then vim.treesitter.start(ev.buf) end
						if vim.bo[ev.buf].indentexpr == "" then vim.bo[ev.buf].indentexpr = "v:lua.vim.treesitter.indentexpr()" end
					end

					if installed[lang] then
						-- parser already installed, start highlighting immediately
						start_treesitter()
						return
					end
					local notify = require("utils.notify")
					ensure_ts_cli(function(ok)
						if not ok then
							notify.warn("Skipping parser install for " .. ft .. ": tree-sitter-cli unavailable")
							return
						end
						TS.install(lang, { summary = true }):await(function()
							installed[lang] = true
							notify.info("Tree-sitter parser installed for " .. ft .. " (" .. lang .. ")")
							start_treesitter()
						end)
					end)
				end,
			})
		end,
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			code = {
				sign = false,
				width = "block",
				right_pad = 1,
			},
			heading = {
				sign = false,
				icons = {},
			},
			paragraph = {
				sign = false,
				padding = false,
			},
		},
	},

	-- Support for PlantUML (Comments for now only never remove this because we can reuse them)
	-- {
	-- 	"aklt/plantuml-syntax",
	-- 	ft = "plantuml",
	-- },
	-- {
	-- 	"https://gitlab.com/itaranto/plantuml.nvim",
	-- 	ft = "plantuml",
	-- 	cmd = "PlantUml",
	-- 	opts = {
	-- 		renderer = {
	-- 			type = "image",
	-- 			options = {
	-- 				prog = "feh",
	-- 				dark_mode = true,
	-- 			},
	-- 		},
	-- 		render_on_write = true,
	-- 	},
	-- 	main = "plantuml",
	-- },
}
