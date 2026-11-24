local vim = vim

local M = {}

--- Get the root directory of the project.
---
--- @param source string|integer Buffer number (0 for current buffer) or file path to begin the search from
--- @return string|nil: The root directory path of the project
M.find_root = function(source, markers)
    return vim.fs.root(source or 0, markers or vim.g.root_markers or {
        ".git",
        "package.json", -- npm
        "Cargo.toml", -- rust
        "build.zig", -- zig
        "stylua.toml", -- lua
        "lazy-lock.json", -- nvim config
        "gradlew",  -- java
        "mvnw",     -- java
    })
end

return setmetatable(M, {
    __index = function(_, key) return require("utils." .. key) end,
})
