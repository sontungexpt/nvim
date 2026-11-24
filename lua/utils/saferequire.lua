local pcall = pcall
local noop = function() end

local EMPTY_MODULE
local proxy = function() return EMPTY_MODULE end
EMPTY_MODULE = setmetatable({}, {
    __index = proxy,
    __call = proxy,
    __newindex = noop,
})

local M = {}

--- Safely loads a module, returning its contents if successful or a no-op proxy otherwise.
---
--- The fallback proxy silently ignores field access, function calls, and assignments,
--- including chained operations, when the requested module cannot be loaded.
---
--- @param name string The name of the module to load.
--- @return table module The loaded module or an empty no-op proxy.
M.safe_require = function(name)
    local ok, module = pcall(require, name)
    if ok then
        return module
    end
    require("utils.notify").error("Module " .. name .. " not found")
    return EMPTY_MODULE
end

return M
