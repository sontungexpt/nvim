local require = require

-- core module
require("core.option")
require("core.environment")
require("core.autocmd")
require("core.keymap").setup()
require("core.bootstrap").boot()
