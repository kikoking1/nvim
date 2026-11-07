-- VS Code style bottom panel (Ctrl+`): a thin sidebar of view icons on the
-- left, and the selected view on the right. Views register themselves:
--   terminal  lua/terminal-tabs.lua   terminals with a tab bar
--   debug     lua/debug-console.lua   debug output with step buttons
--
-- A view is { icon, buf() -> bufnr?, winbar = <'winbar' value>, open(opts) }.
-- open() does whatever setup the view needs and then calls M.show().

local M = {}

local views, order = {}, {}
local current = nil -- view in the panel (kept while hidden, reopened by toggle)
local content, sidebar = nil, nil -- windows
local sidebar_buf = nil
local height = 15
local closing = false
local ns = vim.api.nvim_create_namespace("panel")

local function valid(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

function M.register(name, view)
	views[name] = view
	table.insert(order, name)
end

function M.is_open()
	return valid(content)
end

-- Name of the view on screen, or nil when the panel is hidden.
function M.current()
	return M.is_open() and current or nil
end

function M.content_win()
	return M.is_open() and content or nil
end

local SIDEBAR_WIDTH = 6
-- Each view gets a 3-line tile (icon on the middle line) plus a blank line.
local TILE = 4

-- Highlight groups, derived from the colorscheme so they follow it. The
-- usual TabLine colours are too dim to read (tokyonight's is #3b4261).
local function set_highlights()
	local function get(name)
		return vim.api.nvim_get_hl(0, { name = name, link = false })
	end
	local function set(name, val)
		vim.api.nvim_set_hl(0, name, val)
	end
	local normal, bar, raised, sel = get("Normal"), get("TabLine"), get("CursorLine"), get("TabLineSel")
	local text = get("WinBar").fg or normal.fg

	set("PanelBar", { fg = text, bg = bar.bg })
	-- sidebar
	set("PanelSidebar", { fg = text, bg = bar.bg })
	set("PanelSidebarActive", { bg = raised.bg })
	set("PanelSidebarIcon", { fg = text, bg = bar.bg })
	set("PanelSidebarIconActive", { fg = normal.fg, bg = raised.bg, bold = true })
	set("PanelSidebarAccent", { fg = sel.bg, bg = raised.bg })
	-- terminal tabs
	set("PanelTab", { fg = text, bg = bar.bg })
	set("PanelTabSel", { fg = sel.fg, bg = sel.bg, bold = true })
	-- debug buttons: raised pills with a coloured icon, or dimmed when disabled
	set("PanelButton", { fg = normal.fg, bg = raised.bg, bold = true })
	set("PanelButtonOff", { fg = get("Comment").fg, bg = bar.bg })
	for name, source in pairs({
		Continue = "DiagnosticOk",
		Pause = "DiagnosticWarn",
		Step = "Function",
		Restart = "DiagnosticWarn",
		Stop = "DiagnosticError",
	}) do
		set("PanelIcon" .. name, { fg = get(source).fg, bg = raised.bg, bold = true })
	end
end

local function view_at(line)
	if line % TILE ~= 0 then
		return order[math.ceil(line / TILE)]
	end
end

local function render_sidebar()
	if not (sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf)) then
		return
	end
	local lines = {}
	for i, name in ipairs(order) do
		local top = (i - 1) * TILE
		lines[top + 1] = ""
		lines[top + 2] = "  " .. views[name].icon
		lines[top + 3] = ""
		lines[top + 4] = ""
	end
	vim.bo[sidebar_buf].modifiable = true
	vim.api.nvim_buf_set_lines(sidebar_buf, 0, -1, false, lines)
	vim.bo[sidebar_buf].modifiable = false
	vim.api.nvim_buf_clear_namespace(sidebar_buf, ns, 0, -1)
	for i, name in ipairs(order) do
		local top = (i - 1) * TILE
		local active = name == current
		vim.api.nvim_buf_set_extmark(sidebar_buf, ns, top + 1, 2, {
			end_col = #lines[top + 2],
			hl_group = active and "PanelSidebarIconActive" or "PanelSidebarIcon",
			priority = 200,
		})
		if active then
			-- highlighted tile with an accent bar down its left edge
			for row = top, top + 2 do
				vim.api.nvim_buf_set_extmark(sidebar_buf, ns, row, 0, {
					line_hl_group = "PanelSidebarActive",
					virt_text = { { "▌", "PanelSidebarAccent" } },
					virt_text_pos = "overlay",
				})
			end
		end
	end
end

-- Clicking the sidebar enters its window; switch to the view on the clicked
-- line and hand focus back to the content window.
local function on_sidebar_enter()
	if not valid(sidebar) or vim.api.nvim_get_current_win() ~= sidebar then
		return
	end
	local name = view_at(vim.api.nvim_win_get_cursor(sidebar)[1])
	if name then
		views[name].open({ focus = true })
	elseif M.is_open() then
		vim.api.nvim_set_current_win(content)
	end
end

local function get_sidebar_buf()
	if sidebar_buf and vim.api.nvim_buf_is_valid(sidebar_buf) then
		return sidebar_buf
	end
	sidebar_buf = vim.api.nvim_create_buf(false, true)
	vim.bo[sidebar_buf].bufhidden = "hide"
	vim.bo[sidebar_buf].filetype = "panel-sidebar"
	local pending = false
	vim.api.nvim_create_autocmd({ "WinEnter", "CursorMoved" }, {
		buffer = sidebar_buf,
		callback = function()
			if pending then
				return
			end
			pending = true
			vim.schedule(function()
				pending = false
				on_sidebar_enter()
			end)
		end,
	})
	return sidebar_buf
end

local function set_opts(win, opts)
	for k, v in pairs(opts) do
		vim.wo[win][k] = v
	end
end

local plain = {
	number = false,
	relativenumber = false,
	signcolumn = "no",
	foldcolumn = "0",
	statuscolumn = "",
	list = false,
}

local function open_sidebar()
	sidebar = vim.api.nvim_open_win(get_sidebar_buf(), false, { split = "left", win = content, width = SIDEBAR_WIDTH })
	set_opts(sidebar, plain)
	set_opts(sidebar, {
		winfixwidth = true,
		winfixheight = true,
		cursorline = false,
		wrap = false,
		fillchars = "eob: ",
		winhighlight = "Normal:PanelSidebar,EndOfBuffer:PanelSidebar",
		-- empty bar so the icons line up with the content below its winbar
		winbar = "%#PanelBar# ",
	})
end

-- Show a view's buffer in the panel, opening the panel if needed.
-- opts.focus (default true) moves the cursor into the panel.
function M.show(name, opts)
	opts = opts or {}
	local view = views[name]
	local buf = view and view.buf()
	if not buf then
		return
	end
	if M.is_open() then
		vim.api.nvim_win_set_buf(content, buf)
	else
		content = vim.api.nvim_open_win(buf, false, { split = "below", win = -1, height = height })
		vim.wo[content].winfixheight = true
	end
	if not valid(sidebar) then
		open_sidebar()
	end
	set_opts(content, plain)
	current = name
	vim.wo[content].winbar = view.winbar
	render_sidebar()
	if opts.focus ~= false then
		vim.api.nvim_set_current_win(content)
	end
end

function M.hide()
	closing = true
	if valid(sidebar) then
		vim.api.nvim_win_close(sidebar, true)
	end
	if M.is_open() then
		height = vim.api.nvim_win_get_height(content)
		if #vim.api.nvim_tabpage_list_wins(0) > 1 then
			vim.api.nvim_win_close(content, true)
		else
			-- last window: leave an empty buffer rather than quitting
			vim.api.nvim_win_set_buf(content, vim.api.nvim_create_buf(true, false))
			vim.wo[content].winbar = ""
		end
	end
	content, sidebar = nil, nil
	closing = false
end

-- Show/hide the panel, reopening the view it last showed.
function M.toggle()
	if M.is_open() then
		M.hide()
	else
		views[current or order[1]].open({ focus = true })
	end
end

function M.setup()
	require("terminal-tabs")
	require("debug-console")

	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			set_highlights()
			render_sidebar()
		end,
	})

	-- Closing either panel window (e.g. :q) closes the other one too.
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(args)
			local win = tonumber(args.match)
			if not closing and (win == content or win == sidebar) then
				vim.schedule(M.hide)
			end
		end,
	})

	-- Ctrl+` (VS Code style). Terminals with the kitty keyboard protocol
	-- (Ghostty, WezTerm via `enable_kitty_keyboard`) report it as <C-`>, or
	-- with Shift held as <C-~> / <C-S-`>. Others (Ptyxis, GNOME Terminal, any
	-- VTE terminal) send NUL, which Neovim sees as <C-Space> / <C-@>, so those
	-- are mapped too. Ctrl+Space toggles the panel as a side effect.
	for _, lhs in ipairs({ "<C-e>", "<C-`>", "<C-~>", "<C-S-`>", "<C-Space>", "<C-@>" }) do
		vim.keymap.set({ "n", "t" }, lhs, M.toggle, { desc = "Toggle bottom panel" })
	end
end

return M
