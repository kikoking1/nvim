-- Static key specs with lazy `require`s so harpoon only loads on first use
-- (a `keys = function()` that requires harpoon would load it at startup).
local function list_action(fn)
  return function()
    local harpoon = require("harpoon")
    fn(harpoon, harpoon:list())
  end
end

local function nav(idx)
  return list_action(function(_, list)
    list:select(idx)
  end)
end

return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    {
      "<leader>a",
      list_action(function(_, list)
        list:add()
      end),
      desc = "Harpoon: [A]dd file",
    },
    {
      "<leader>h",
      list_action(function(harpoon, list)
        harpoon.ui:toggle_quick_menu(list)
      end),
      desc = "Harpoon: toggle menu",
    },
    { "<A-j>", nav(1), desc = "Harpoon: file 1" },
    { "<A-k>", nav(2), desc = "Harpoon: file 2" },
    { "<A-l>", nav(3), desc = "Harpoon: file 3" },
    { "<A-n>", nav(4), desc = "Harpoon: file 4" },
  },
  config = function()
    require("harpoon"):setup()
  end,
}
