-- VS Code style activity bar to the left of neo-tree: a Files icon (the usual
-- file tree) and a Git icon (neo-tree's git_status source: changed files).
-- It opens and closes with neo-tree; see the event handlers in
-- lua/plugins/neo-tree.lua.

local M = {}

local bar = nil
local tree_win = nil

local function get_bar()
	bar = bar
		or require("sidebar").new({
			filetype = "activity-bar",
			items = {
				{ name = "filesystem", icon = "\u{eaf0}" }, -- nf-cod-files
				{ name = "git_status", icon = "\u{ea68}" }, -- nf-cod-source_control
			},
			on_select = function(source)
				if source then
					vim.cmd("Neotree show left " .. source)
				end
				-- neo-tree reuses its window when switching sources, but doesn't
				-- move the cursor into it when called from another window
				if tree_win and vim.api.nvim_win_is_valid(tree_win) then
					vim.api.nvim_set_current_win(tree_win)
				end
			end,
		})
	return bar
end

-- neo-tree opened (or switched source) in window win.
function M.attach(win, source)
	tree_win = win
	local b = get_bar()
	if not b:is_open() then
		local width = vim.api.nvim_win_get_width(win)
		b:open({ split = "left", win = win })
		-- the bar takes its columns from neo-tree; give them back
		vim.api.nvim_win_set_width(win, width)
	end
	b:render(source)
end

function M.detach()
	if bar then
		bar:close()
	end
	tree_win = nil
end

-- If neo-tree's window goes away without its close event (e.g. :only),
-- take the bar with it.
vim.api.nvim_create_autocmd("WinClosed", {
	callback = function(args)
		if tree_win and tonumber(args.match) == tree_win then
			vim.schedule(M.detach)
		end
	end,
})

return M
