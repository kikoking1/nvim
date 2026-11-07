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
local content = nil -- window
local sidebar = nil -- lua/sidebar.lua instance, created on first show
local height = 15
local closing = false

local function valid(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

function M.register(name, view)
	views[name] = view
	table.insert(order, { name = name, icon = view.icon })
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

-- Clicking a sidebar tile switches to that view; clicking empty space just
-- hands focus back to the content window.
local function on_select(name)
	if name then
		views[name].open({ focus = true })
	elseif M.is_open() then
		vim.api.nvim_set_current_win(content)
	end
end

local function get_sidebar()
	sidebar = sidebar
		or require("sidebar").new({
			filetype = "panel-sidebar",
			items = order,
			on_select = on_select,
			-- empty bar so the icons line up with the content below its winbar
			winbar = "%#PanelBar# ",
		})
	return sidebar
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
	local bar = get_sidebar()
	if not bar:is_open() then
		vim.wo[bar:open({ split = "left", win = content })].winfixheight = true
	end
	set_opts(content, plain)
	current = name
	vim.wo[content].winbar = view.winbar
	bar:render(name)
	if opts.focus ~= false then
		vim.api.nvim_set_current_win(content)
	end
end

function M.hide()
	closing = true
	if sidebar then
		sidebar:close()
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
	content = nil
	closing = false
end

-- Show/hide the panel, reopening the view it last showed.
function M.toggle()
	if M.is_open() then
		M.hide()
	else
		views[current or order[1].name].open({ focus = true })
	end
end

function M.setup()
	require("terminal-tabs")
	require("debug-console")

	set_highlights()
	vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

	-- Closing either panel window (e.g. :q) closes the other one too.
	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function(args)
			local win = tonumber(args.match)
			if not closing and (win == content or (sidebar and win == sidebar.win)) then
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
