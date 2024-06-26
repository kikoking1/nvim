-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()
config.default_domain = "WSL:Ubuntu"
-- This is where you actually apply your config choices

config.font = wezterm.font("JetBrains Mono")
local dimmer = { brightness = 0.02 }
config.background = {
	-- This is the deepest/back-most layer. It will be rendered first
	{
		source = {
			File = "C:\\Users\\kiko\\OneDrive\\Desktop\\Wallpapers\\mob-psycho.jpg",
		},
		hsb = dimmer,
	},
}
-- and finally, return the configuration to wezterm
return config
