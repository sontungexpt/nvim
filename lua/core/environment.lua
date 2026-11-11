local uv = vim.uv or vim.loop

local sep = (uv.os_uname().sysname == "Windows_NT") and ";" or ":"

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"

local path = vim.env.PATH or ""
vim.env.PATH = mason_bin .. sep .. path
