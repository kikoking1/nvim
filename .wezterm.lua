local wezterm = require("wezterm")
local config = wezterm.config_builder()
local mux = wezterm.mux

config.window_padding = {
  left = 42,
  right = 42,
  top = 0,
  bottom = 0,
}

wezterm.on("gui-startup", function(cmd)
  -- Allow `wezterm start -- something` to affect what we spawn
  local tab, pane, window = mux.spawn_window(cmd or {})

  -- Maximize the window
  window:gui_window():maximize()
end)

-- Set Operator Mono as the primary font, and explicitly tell WezTerm
-- to fall back to its built-in Nerd Font for any icons.
config.font = wezterm.font_with_fallback({
  "Operator Mono",
  "Symbols Nerd Font Mono",
})

-- Force true italics (cursive) when the terminal asks for italic text
config.font_rules = {
  {
    italic = true,
    font = wezterm.font({
      family = "Operator Mono",
      style = "Italic",
    }),
  },
  {
    italic = true,
    intensity = "Bold",
    font = wezterm.font({
      family = "Operator Mono",
      weight = "Bold",
      style = "Italic",
    }),
  },
}

-- Adjust font size to your liking
config.font_size = 14.0

config.background = {
  {
    source = {
      File = "/home/kiko/.config/nvim/wallpaper.jpg",
    },
    -- Correct way to scale without warping
    width = "Cover",
    height = "Cover",

    -- Tell WezTerm not to tile/repeat the image
    repeat_x = "NoRepeat",
    repeat_y = "NoRepeat",

    -- Center the image so cropping is uniform
    horizontal_align = "Center",
    vertical_align = "Middle",

    -- Opacity/Dimming settings
    hsb = { brightness = 0.03, hue = 1.0, saturation = 1.0 },
  },
}

return config
