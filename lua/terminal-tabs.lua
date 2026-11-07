-- VS Code style bottom terminal panel: one split at the bottom holding several
-- terminals, with a clickable tab bar in the winbar ("+" adds a terminal,
-- clicking a tab switches to it, "✕" kills it).
--
-- Shell tabs close themselves when the shell exits. Command tabs (M.run) stay
-- open after the command exits so its output can still be read.

local M = {}

local tabs = {} -- ordered list of { id, buf, name, key? }
local active = nil -- id of the tab shown in the panel
local win = nil -- panel window, nil when hidden
local height = 15
local next_id = 1
local shell_count = 0

local function find(id)
	for i, tab in ipairs(tabs) do
		if tab.id == id then
			return i, tab
		end
	end
end

local function panel_open()
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function render()
	if not panel_open() then
		return
	end
	local parts = {}
	for _, tab in ipairs(tabs) do
		local hl = tab.id == active and "%#TabLineSel#" or "%#TabLine#"
		table.insert(
			parts,
			string.format(
				"%s%%%d@v:lua.TerminalTabsSelect@ %s %%X%%%d@v:lua.TerminalTabsClose@✕ %%X",
				hl,
				tab.id,
				tab.name,
				tab.id
			)
		)
	end
	table.insert(parts, "%#TabLine#%@v:lua.TerminalTabsNew@ + %X%#TabLineFill#")
	vim.wo[win].winbar = table.concat(parts, "%#TabLineFill# ")
end

local function show(id)
	local _, tab = find(id)
	if not tab then
		return
	end
	if not panel_open() then
		vim.cmd("botright split")
		win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_height(win, height)
		vim.wo[win].winfixheight = true
	end
	vim.api.nvim_win_set_buf(win, tab.buf)
	vim.api.nvim_set_current_win(win)
	active = id
	render()
	vim.cmd("startinsert")
end

local function remove(id)
	local i, tab = find(id)
	if not tab then
		return
	end
	table.remove(tabs, i)
	if active == id then
		local neighbour = tabs[i] or tabs[i - 1]
		active = neighbour and neighbour.id
		if not neighbour then
			M.hide()
		elseif panel_open() then
			show(neighbour.id)
		end
	end
	render()
end

-- Create a terminal tab. cmd nil means an interactive shell.
local function create(cmd, opts)
	opts = opts or {}
	local id = next_id
	next_id = next_id + 1

	local name = opts.name
	if not name then
		shell_count = shell_count + 1
		name = vim.fn.fnamemodify(vim.o.shell, ":t") .. " " .. shell_count
	end

	local buf = vim.api.nvim_create_buf(false, false)
	vim.bo[buf].bufhidden = "hide"
	table.insert(tabs, { id = id, buf = buf, name = name, key = opts.key })
	show(id)

	vim.fn.jobstart(cmd or vim.o.shell, { term = true, cwd = opts.cwd })

	vim.api.nvim_create_autocmd("TermClose", {
		buffer = buf,
		once = true,
		callback = function()
			if not cmd then
				vim.schedule(function()
					M.close(id)
				end)
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWipeout", {
		buffer = buf,
		once = true,
		callback = function()
			vim.schedule(function()
				remove(id)
			end)
		end,
	})
	return id
end

function M.new()
	create(nil)
end

function M.select(id)
	show(id)
end

-- Kill the tab's process and remove it.
function M.close(id)
	local _, tab = find(id)
	if not tab then
		return
	end
	local buf = tab.buf
	remove(id)
	if vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.fn.jobstop, vim.bo[buf].channel)
		vim.api.nvim_buf_delete(buf, { force = true })
	end
end

function M.hide()
	if not panel_open() then
		return
	end
	height = vim.api.nvim_win_get_height(win)
	if #vim.api.nvim_tabpage_list_wins(0) > 1 then
		vim.api.nvim_win_close(win, true)
	else
		-- last window: leave an empty buffer rather than quitting
		vim.api.nvim_win_set_buf(win, vim.api.nvim_create_buf(true, false))
		vim.wo[win].winbar = ""
	end
	win = nil
end

-- Show/hide the panel. Showing with no terminals opens a new shell.
function M.toggle()
	if panel_open() then
		M.hide()
	elseif active then
		show(active)
	else
		M.new()
	end
end

-- Run a command in its own tab. Tabs with the same opts.key are replaced, so
-- running the same thing again restarts it instead of piling up tabs.
function M.run(cmd, opts)
	opts = opts or {}
	if opts.key then
		for _, tab in ipairs(tabs) do
			if tab.key == opts.key then
				M.close(tab.id)
				break
			end
		end
	end
	return create(cmd, opts)
end

-- winbar click handlers: (minwid, clicks, button, mods)
function _G.TerminalTabsSelect(id)
	M.select(id)
end
function _G.TerminalTabsClose(id)
	M.close(id)
end
function _G.TerminalTabsNew()
	M.new()
end

function M.setup()
	-- Ctrl+` (VS Code style). Terminals report it as <C-`>, or with Shift held
	-- as <C-~> / <C-S-`>, so all are mapped. Needs a terminal that sends
	-- distinct Ctrl+key codes (kitty keyboard protocol): Ghostty does by
	-- default, WezTerm via `enable_kitty_keyboard` in .wezterm.lua. Without it,
	-- Ctrl+` is sent as NUL (same as Ctrl+Space).
	for _, lhs in ipairs({ "<C-e>", "<C-`>", "<C-~>", "<C-S-`>" }) do
		vim.keymap.set({ "n", "t" }, lhs, M.toggle, { desc = "Toggle bottom terminal panel" })
	end
end

return M
