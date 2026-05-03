-- Order matters: options set leader before keymaps reference it,
-- and lazy needs the leader set before reading plugin specs.
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

require("terminal-maximize").setup()
