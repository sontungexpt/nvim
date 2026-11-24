local vim = vim
local api, uv = vim.api, vim.uv

local M = {}

local function echo(str, opts)
	vim.cmd.redraw()
	api.nvim_echo({ { str, "Bold" } }, false, opts)
end

local function do_lazy_events()
	-- Trigger lazy loading events after UI is ready
	local boot_grp = api.nvim_create_augroup("__core_lazy_boot__", { clear = true })

	local a1, a2

	a1 = api.nvim_create_autocmd({ "UIEnter", "BufEnter", "BufNewFile" }, {
		group = boot_grp,
		callback = function(args)
			if args.event == "UIEnter" then
				vim.g.ui_entered = true

				local ns = api.nvim_create_namespace("__first_key_lazy_loaded__")
				vim.on_key(function()
					vim.on_key(nil, ns)
					api.nvim_exec_autocmds("User", { pattern = "FirstKeyReady" })
				end, ns)
			end

			local bufnr, file = args.buf, args.file
			if vim.g.ui_entered and file ~= "" and vim.bo[bufnr].buftype ~= "nofile" then
				api.nvim_del_autocmd(a1)
				api.nvim_exec_autocmds("User", { pattern = "FirstFileReady" })
				vim.schedule(function() api.nvim_exec_autocmds("FileType", { buffer = bufnr }) end)
			end
		end,
	})

	-- Detect git repositories for lazy loading
	a2 = api.nvim_create_autocmd("BufEnter", {
		group = boot_grp,
		callback = function(args)
			local file = args.file
			if file == "" or vim.bo[args.buf].buftype == "nofile" then return end
			api.nvim_del_autocmd(a2)
			uv.spawn("git", {
				args = { "-C", vim.fs.dirname(file), "rev-parse" },
				env = nil,
				cwd = nil,
				uid = nil,
				gid = nil,
				verbatim = false,
				detached = false,
				hide = false,
				stdio = nil,
			}, function(exit_code)
				if exit_code == 0 then
					vim.schedule(function() api.nvim_exec_autocmds("User", { pattern = "FirstGitReady" }) end)
				end
			end)
		end,
	})
end

local function do_boot(install_path)
	vim.opt.rtp:prepend(install_path)

	require("lazy").setup("plugins", {
		defaults = {
			lazy = true,
			version = false,
		},
		ui = {
			-- size = { width = 0.8, height = 0.8 },
			wrap = true,
			border = "single",
		},
		performance = {
			rtp = {
				disabled_plugins = {
					"2html_plugin",
					"getscript",
					"getscriptPlugin",
					"gzip",
					"logiPat",

					-- disable netrw
					"netrw",
					"netrwPlugin",
					"netrwSettings",
					"netrwFileHandlers",
					"netrw_gitignore",

					"matchit",
					"tar",
					"tarPlugin",
					"rrhelper",

					-- spelling
					"spellfile_plugin",
					"spellfile",

					"vimball",
					"vimballPlugin",
					"tutor_mode_plugin",
					"remote_plugins",
					"synmenu",
					"optwin",
					"compiler",
					"bugreport",
					"zip",
					"zipPlugin",
				},
			},
		},
	})

	do_lazy_events()
end

function M.boot()
	if vim.version().minor < 10 then
		echo("Error: Bootstrap requires at least nvim 0.10", { err = true })
		return
	end

	local install_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

	if uv.fs_stat(install_path) then
		do_boot(install_path)
		return
	end

	echo("  Installing lazy.nvim and plugins ...")
	vim.system(
		{
			"git",
			"clone",
			"--filter=blob:none",
			"--branch=stable",
			"https://github.com/folke/lazy.nvim.git",
			install_path,
		},
		nil,
		function(out)
			vim.schedule(function()
				if out.code == 0 then
					echo("lazy.nvim installed successfully!. Loading plugins ...")
					do_boot(install_path)
				else
					echo("Error: Unable to install lazy.nvim and plugins", { err = true })
				end
			end)
		end
	)
end

return M
