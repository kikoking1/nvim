-- Terminal view of the bottom panel (lua/panel.lua): several terminals with a
-- clickable tab bar in the winbar ("+" adds a terminal, clicking a tab
-- switches to it, "✕" kills it).
--
-- Shell tabs close themselves when the shell exits. Command tabs (M.run) stay
-- open after the command exits so its output can still be read.

local panel = require("panel")

local M = {}

local tabs = {} -- ordered list of { id, buf, name, key? }
local active = nil -- id of the tab shown in the view
local next_id = 1
local shell_count = 0

local function find(id)
	for i, tab in ipairs(tabs) do
		if tab.id == id then
			return i, tab
		end
	end
end

function _G.TerminalTabsWinbar()
	local parts = {}
	for _, tab in ipairs(tabs) do
		local hl = tab.id == active and "%#PanelTabSel#" or "%#PanelTab#"
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
	table.insert(parts, "%#PanelButton#%@v:lua.TerminalTabsNew@ + %X")
	return " " .. table.concat(parts, "%#PanelBar# ") .. "%#PanelBar#"
end

local function show(id)
	active = id
	panel.show("terminal")
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
		if panel.current() == "terminal" then
			if neighbour then
				show(neighbour.id)
			else
				panel.hide()
			end
		end
	end
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

	-- start the job in the panel window so it gets the right size
	vim.api.nvim_win_call(panel.content_win(), function()
		vim.fn.jobstart(cmd or vim.o.shell, { term = true, cwd = opts.cwd })
	end)

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
	if find(id) then
		show(id)
	end
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

panel.register("terminal", {
	icon = "", -- nf-cod-terminal
	winbar = "%{%v:lua.TerminalTabsWinbar()%}",
	buf = function()
		local _, tab = find(active)
		return tab and tab.buf
	end,
	-- show the last used terminal, or start a shell if there are none
	open = function()
		if active then
			show(active)
		else
			M.new()
		end
	end,
})

return M
