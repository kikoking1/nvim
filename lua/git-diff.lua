-- VS Code style diff of a changed file, opened from the Git view of neo-tree.
-- Each diff is its own buffer tab in the bufferline, "<file> (diff)". While
-- that tab is shown, its window holds the old version (read-only) and a split
-- to its right holds the file itself, to edit as usual. Each change gets a
-- ">>" button in the old version's gutter that reverts just that hunk in the
-- file (unsaved, like any other edit).
--
-- Switching the left pane to another tab closes the file pane and ends diff
-- mode; opening another file in the file pane closes the old version pane.
-- Closing the tab (bufferline x, <M-D>, or q) leaves the file showing.
--
-- The old version is the index (what's staged) when the file has unstaged
-- changes, else HEAD, so a fully staged file still shows its changes. New
-- files compare against nothing.

local git = require("git")

local M = {}

-- diff buffer -> { buf, path, file_buf, base, label, hunks, sign_lines,
--                  left_win?, right_win? } (windows set while shown)
local entries = {}
local active = nil -- the entry on screen
local diff = vim.text and vim.text.diff or vim.diff
local group = vim.api.nvim_create_augroup("git-diff", { clear = true })

local function valid(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function shows(win, buf)
	return valid(win) and vim.api.nvim_win_get_buf(win) == buf
end

local function set_highlights()
	vim.api.nvim_set_hl(0, "GitDiffRevert", { link = "DiagnosticWarn", default = true })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })

-- Recompute the hunks (old vs. the file buffer as it is now) and where their
-- ">>" buttons go in the old version pane.
local function update_hunks(entry)
	local old = table.concat(entry.base, "\n") .. "\n"
	local new = table.concat(vim.api.nvim_buf_get_lines(entry.file_buf, 0, -1, false), "\n") .. "\n"
	entry.hunks = diff(old, new, { result_type = "indices" }) or {}
	entry.sign_lines = {}
	for i, h in ipairs(entry.hunks) do
		-- a pure insertion (no old lines) shows after line h[1] of the old side
		local line = math.max(h[1], 1)
		entry.sign_lines[line] = entry.sign_lines[line] or i
	end
	if valid(entry.left_win) then
		pcall(vim.api.nvim__redraw, { win = entry.left_win, statuscolumn = true })
	end
end

-- Old version gutter: ">>" on lines that start a hunk, then the line number.
-- Every row gets the same click region: Neovim keeps the click regions of
-- only one gutter row (not necessarily the clicked one), so the handler looks
-- up the clicked line itself.
function _G.GitDiffStatuscol()
	local click = "%@v:lua.GitDiffClick@"
	if vim.v.virtnum ~= 0 then
		return click .. "    %X     "
	end
	local i = active and active.sign_lines[vim.v.lnum]
	local button = i and "%#GitDiffRevert# >> " or "    "
	return click .. button .. "%X%#LineNr#" .. string.format("%4d ", vim.v.lnum)
end

-- statuscolumn click handler: revert the hunk whose ">>" is on the clicked line
function _G.GitDiffClick()
	local pos = vim.fn.getmousepos()
	if active and pos.winid == active.left_win and pos.wincol <= 4 then
		local i = active.sign_lines[pos.line]
		if i then
			M.revert_hunk(i)
		end
	end
end

-- Put hunk i's old lines back into the file.
function M.revert_hunk(i)
	local entry = active
	local h = entry and entry.hunks[i]
	if not h then
		return
	end
	local start_a, count_a, start_b, count_b = h[1], h[2], h[3], h[4]
	local old = count_a > 0 and vim.list_slice(entry.base, start_a, start_a + count_a - 1) or {}
	if count_b == 0 then
		-- lines were deleted: re-insert them after line start_b
		vim.api.nvim_buf_set_lines(entry.file_buf, start_b, start_b, false, old)
	else
		vim.api.nvim_buf_set_lines(entry.file_buf, start_b - 1, start_b - 1 + count_b, false, old)
	end
	update_hunks(entry)
	if valid(entry.right_win) then
		vim.api.nvim_win_call(entry.right_win, function()
			vim.cmd("diffupdate")
		end)
	end
end

-- Show entry's panes: the old version in win, the file in a split to its right.
local function attach(entry, win)
	if active and active ~= entry then
		M.hide(active)
	end
	entry.left_win = win
	if not shows(entry.right_win, entry.file_buf) then
		entry.right_win = vim.api.nvim_open_win(entry.file_buf, false, { split = "right", win = win })
	end
	active = entry
	local rel = vim.fn.fnamemodify(entry.path, ":~:.")
	for _, w in ipairs({ entry.left_win, entry.right_win }) do
		vim.api.nvim_win_call(w, function()
			vim.cmd("diffthis")
		end)
		vim.wo[w].foldenable = false -- show the whole file, like VS Code
		vim.wo[w].wrap = false
	end
	local L = vim.wo[entry.left_win]
	L.number = true
	L.relativenumber = false
	L.signcolumn = "no"
	L.statuscolumn = "%{%v:lua.GitDiffStatuscol()%}"
	L.winbar = "%#WinBar# " .. rel .. "  (" .. entry.label .. ", read-only)"
	vim.wo[entry.right_win].winbar = "%#WinBar# " .. rel .. "  (working tree)"
	update_hunks(entry)
end

-- End diff mode in entry's windows and put back the options attach() changed.
-- Returns the windows the panes were in. Closing them is up to the caller.
function M.hide(entry)
	local L, R = entry.left_win, entry.right_win
	entry.left_win, entry.right_win = nil, nil
	if active == entry then
		active = nil
	end
	for _, w in ipairs({ L, R }) do
		if valid(w) then
			vim.api.nvim_win_call(w, function()
				vim.cmd("diffoff")
			end)
			vim.wo[w].winbar = ""
			vim.wo[w].wrap = vim.go.wrap
		end
	end
	if valid(L) then
		local wo = vim.wo[L]
		wo.statuscolumn = ""
		wo.number = vim.go.number
		wo.relativenumber = vim.go.relativenumber
		wo.signcolumn = vim.go.signcolumn
	end
	return L, R
end

-- Close a diff tab: the left pane switches to the file, the file pane closes.
function M.close(entry)
	entry = entry or active
	if not entry then
		return
	end
	if shows(entry.left_win, entry.buf) then
		-- triggers the BufWinLeave handler, which closes the file pane
		vim.api.nvim_win_set_buf(entry.left_win, entry.file_buf)
	end
	if vim.api.nvim_buf_is_valid(entry.buf) then
		vim.api.nvim_buf_delete(entry.buf, { force = true })
	end
end

-- The old version of path to compare against: lines and a label.
local function base_version(path)
	local entries_, root = git.status(path)
	local e = entries_[1]
	if not e or e.x == "?" or (e.x == "A" and e.y == " ") then
		return {}, "new file"
	end
	local rev, label = ":", "Index"
	if e.y == " " and e.x ~= "A" then
		rev, label = "HEAD:", "HEAD"
	end
	local rel = (e.orig or e.path):sub(#root + 2)
	local res = vim.system({ "git", "show", rev .. rel }, { cwd = root, text = true }):wait()
	if res.code ~= 0 then
		return {}, label
	end
	local lines = vim.split(res.stdout, "\n", { plain = true })
	if lines[#lines] == "" then
		table.remove(lines)
	end
	return lines, label
end

local function set_base(entry)
	entry.base, entry.label = base_version(entry.path)
	vim.bo[entry.buf].modifiable = true
	vim.api.nvim_buf_set_lines(entry.buf, 0, -1, false, entry.base)
	vim.bo[entry.buf].modifiable = false
	vim.bo[entry.buf].modified = false
end

local function find_entry(path)
	for _, entry in pairs(entries) do
		if entry.path == path then
			return entry
		end
	end
end

local function new_entry(path)
	local buf = vim.api.nvim_create_buf(true, true)
	vim.bo[buf].bufhidden = "hide"
	-- the bufferline shows the part after the last "/": "<file> (diff)"
	vim.api.nvim_buf_set_name(buf, "git-diff://" .. path .. " (diff)")
	vim.bo[buf].filetype = vim.filetype.match({ filename = path }) or ""
	vim.b[buf].git_diff = true -- lua/editor-win.lua treats it as a code window

	local file_buf = vim.fn.bufadd(path)
	vim.bo[file_buf].buflisted = true
	vim.fn.bufload(file_buf)

	local entry = { buf = buf, path = path, file_buf = file_buf, hunks = {}, sign_lines = {} }
	entries[buf] = entry
	vim.keymap.set("n", "q", function()
		M.close(entry)
	end, { buffer = buf, desc = "Close the git diff" })

	-- The tab left its window (another tab shown there, or the window /
	-- buffer closed). If the window is still there, it shows another tab:
	-- close the file pane too. If not, keep the file pane as a normal window.
	vim.api.nvim_create_autocmd("BufWinLeave", {
		group = group,
		buffer = buf,
		callback = function()
			vim.schedule(function()
				if entry.left_win and shows(entry.left_win, buf) then
					return -- still visible after all
				end
				local L, R = M.hide(entry)
				if valid(L) and shows(R, file_buf) and L ~= R then
					vim.api.nvim_win_close(R, true)
				end
			end)
		end,
	})
	-- closed: bufferline's x runs :bdelete, which only unlists the buffer, so
	-- wipe it too (a later diff of the same file makes a fresh tab)
	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = group,
		buffer = buf,
		callback = function()
			entries[buf] = nil
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(buf) then
					pcall(vim.api.nvim_buf_delete, buf, { force = true })
				end
			end)
		end,
	})
	-- keep the hunks current while editing
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
		group = group,
		buffer = file_buf,
		callback = function()
			if active == entry then
				update_hunks(entry)
			end
		end,
	})
	return entry
end

-- Showing a diff tab in a window opens its panes. Another file opened in the
-- file pane ends the diff and closes the old version pane.
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = group,
	callback = function(args)
		-- the window the buffer entered; by the time the scheduled part runs
		-- the cursor may be elsewhere
		local win = vim.api.nvim_get_current_win()
		vim.schedule(function()
			if active and win == active.right_win and args.buf ~= active.file_buf and shows(win, args.buf) then
				local entry = active
				local L = M.hide(entry)
				if shows(L, entry.buf) and #vim.api.nvim_tabpage_list_wins(0) > 1 then
					vim.api.nvim_win_close(L, true)
				end
			end
			local entry = entries[args.buf]
			if entry and shows(win, args.buf) then
				attach(entry, win)
			end
		end)
	end,
})

-- The file pane closed (e.g. :q): show the file in place of the old version.
vim.api.nvim_create_autocmd("WinClosed", {
	group = group,
	callback = function(args)
		local entry = active
		if entry and tonumber(args.match) == entry.right_win then
			vim.schedule(function()
				local L = M.hide(entry)
				if shows(L, entry.buf) then
					vim.api.nvim_win_set_buf(L, entry.file_buf)
				end
			end)
		end
	end,
})

-- Open path's diff tab (creating it, or refreshing its old version).
function M.open(path)
	local entry = find_entry(path) or new_entry(path)
	set_base(entry)
	local win = require("editor-win").show(entry.buf)
	attach(entry, win)
	-- Stay in the old version pane: the bufferline marks the buffer under the
	-- cursor as the selected tab, so this keeps the diff tab selected (and
	-- <M-D> closes it, not the file). Start at the first change.
	vim.api.nvim_set_current_win(win)
	local first = entry.hunks[1]
	if first then
		pcall(vim.api.nvim_win_set_cursor, win, { math.max(first[1], 1), 0 })
	end
end

-- After staging / discarding: refresh every diff tab's old version, and close
-- the ones with no changes left.
function M.refresh()
	for _, entry in ipairs(vim.tbl_values(entries)) do
		if #git.status(entry.path) == 0 then
			M.close(entry)
		else
			set_base(entry)
			if active == entry then
				attach(entry, entry.left_win)
			end
		end
	end
end

return M
