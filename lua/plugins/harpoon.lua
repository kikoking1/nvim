return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = function()
    local harpoon = require("harpoon")

    local function nav(idx)
      return function()
        harpoon:list():select(idx)
      end
    end

    return {
      {
        "<leader>a",
        function()
          harpoon:list():add()
        end,
        desc = "Harpoon: [A]dd file",
      },
      {
        "<leader>h",
        function()
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: toggle menu",
      },
      { "<A-j>", nav(1), desc = "Harpoon: file 1" },
      { "<A-k>", nav(2), desc = "Harpoon: file 2" },
      { "<A-l>", nav(3), desc = "Harpoon: file 3" },
      { "<A-n>", nav(4), desc = "Harpoon: file 4" },
    }
  end,
  config = function()
    require("harpoon"):setup()
  end,
}
