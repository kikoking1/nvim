-- A column of clickable icon tiles, like VS Code's activity bar. Used by the
-- bottom panel (lua/panel.lua) and the Files / Git bar beside neo-tree
-- (lua/activity-bar.lua).

local M = {}

local WIDTH = 6
-- Each item gets a 3-line tile (icon on the middle line) plus a blank line.
local TILE = 4
local ns = vim.api.nvim_create_namespace("sidebar")

-- Derived from the colorscheme so they follow it.
local function set_highlights()
	local function get(name)
		return vim.api.nvim_get_hl(0, { name = name, link = false })
	end
	local normal, bar, raised, sel = get("Normal"), get("TabLine"), get("CursorLine"), get("TabLineSel")
	local text = get("WinBar").fg or normal.fg
	vim.api.nvim_set_hl(0, "Sidebar", { fg = text, bg = bar.bg })
	vim.api.nvim_set_hl(0, "SidebarActive", { bg = raised.bg })
	vim.api.nvim_set_hl(0, "SidebarIcon", { fg = text, bg = bar.bg })
	vim.api.nvim_set_hl(0, "SidebarIconActive", { fg = normal.fg, bg = raised.bg, bold = true })
	vim.api.nvim_set_hl(0, "SidebarAccent", { fg = sel.bg, bg = raised.bg })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

local Sidebar = {}
Sidebar.__index = Sidebar

-- opts = {
--   filetype = string,
--   items = { { name = string, icon = string }, ... },
--   on_select = fun(name?)  -- a tile (or empty space, nil) was clicked; must
--                           -- move the cursor out of the sidebar
--   winbar = string?        -- e.g. a blank bar to line up with a neighbour's
-- }
function M.new(opts)
	local self = setmetatable({ opts = opts, current = nil, win = nil }, Sidebar)
	self.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[self.buf].bufhidden = "hide"
	vim.bo[self.buf].filetype = opts.filetype

	-- Clicking enters the sidebar window: act on the clicked line.
	local pending = false
	vim.api.nvim_create_autocmd({ "WinEnter", "CursorMoved" }, {
		buffer = self.buf,
		callback = function()
			if pending then
				return
			end
			pending = true
			vim.schedule(function()
				pending = false
				if self:is_open() and vim.api.nvim_get_current_win() == self.win then
					local line = vim.api.nvim_win_get_cursor(self.win)[1]
					local item = line % TILE ~= 0 and opts.items[math.ceil(line / TILE)]
					opts.on_select(item and item.name or nil)
				end
			end)
		end,
	})
	self:render()
	return self
end

function Sidebar:is_open()
	return self.win ~= nil and vim.api.nvim_win_is_valid(self.win)
end

-- Highlight the tile of item `current`.
function Sidebar:render(current)
	self.current = current or self.current
	local lines = {}
	for i, item in ipairs(self.opts.items) do
		local top = (i - 1) * TILE
		lines[top + 1] = ""
		lines[top + 2] = "  " .. item.icon
		lines[top + 3] = ""
		lines[top + 4] = ""
	end
	vim.bo[self.buf].modifiable = true
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
	vim.bo[self.buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
	for i, item in ipairs(self.opts.items) do
		local top = (i - 1) * TILE
		local active = item.name == self.current
		vim.api.nvim_buf_set_extmark(self.buf, ns, top + 1, 2, {
			end_col = #lines[top + 2],
			hl_group = active and "SidebarIconActive" or "SidebarIcon",
			priority = 200,
		})
		if active then
			-- highlighted tile with an accent bar down its left edge
			for row = top, top + 2 do
				vim.api.nvim_buf_set_extmark(self.buf, ns, row, 0, {
					line_hl_group = "SidebarActive",
					virt_text = { { "▌", "SidebarAccent" } },
					virt_text_pos = "overlay",
				})
			end
		end
	end
end

-- Open the sidebar as a split of another window: config is passed to
-- nvim_open_win, e.g. { split = "left", win = other }.
function Sidebar:open(config)
	self.win = vim.api.nvim_open_win(self.buf, false, vim.tbl_extend("force", config, { width = WIDTH }))
	local wo = vim.wo[self.win]
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.foldcolumn = "0"
	wo.statuscolumn = ""
	wo.list = false
	wo.winfixwidth = true
	wo.cursorline = false
	wo.wrap = false
	wo.fillchars = "eob: "
	wo.winhighlight = "Normal:Sidebar,EndOfBuffer:Sidebar"
	wo.winbar = self.opts.winbar or ""
	return self.win
end

function Sidebar:close()
	if self:is_open() then
		vim.api.nvim_win_close(self.win, true)
	end
	self.win = nil
end

return M
