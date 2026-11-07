-- VS Code style side-by-side diff of a changed file, opened from the Git view
-- of neo-tree. Left: the old version (read-only). Right: the file itself, to
-- edit as usual. Each change gets a ">>" button in the left pane's gutter that
-- reverts just that hunk in the right pane (unsaved, like any other edit).
--
-- The old version is the index (what's staged) when the file has unstaged
-- changes, else HEAD, so a fully staged file still shows its changes. New
-- files compare against nothing.

local git = require("git")

local M = {}

local state = nil -- { path, left_win, right_win, left_buf, right_buf, base, hunks, sign_lines }
local group = vim.api.nvim_create_augroup("git-diff", { clear = true })
local switching = false -- set while M.open swaps buffers, to not tear down
local diff = vim.text and vim.text.diff or vim.diff

local function valid(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win)
end

local function set_highlights()
	vim.api.nvim_set_hl(0, "GitDiffRevert", { link = "DiagnosticWarn", default = true })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

-- Recompute the hunks (old vs. the right buffer as it is now) and where their
-- ">>" buttons go in the left pane.
local function update_hunks()
	if not state then
		return
	end
	local old = table.concat(state.base, "\n") .. "\n"
	local new = table.concat(vim.api.nvim_buf_get_lines(state.right_buf, 0, -1, false), "\n") .. "\n"
	state.hunks = diff(old, new, { result_type = "indices" }) or {}
	state.sign_lines = {}
	for i, h in ipairs(state.hunks) do
		-- a pure insertion (no old lines) shows after line h[1] of the old side
		local line = math.max(h[1], 1)
		state.sign_lines[line] = state.sign_lines[line] or i
	end
	if valid(state.left_win) then
		pcall(vim.api.nvim__redraw, { win = state.left_win, statuscolumn = true })
	end
end

-- Left pane gutter: ">>" on lines that start a hunk, then the line number.
-- Every row gets the same click region: Neovim keeps the click regions of
-- only one gutter row (not necessarily the clicked one), so the handler looks
-- up the clicked line itself.
function _G.GitDiffStatuscol()
	local click = "%@v:lua.GitDiffClick@"
	if vim.v.virtnum ~= 0 then
		return click .. "    %X     "
	end
	local i = state and state.sign_lines and state.sign_lines[vim.v.lnum]
	local button = i and "%#GitDiffRevert# >> " or "    "
	return click .. button .. "%X%#LineNr#" .. string.format("%4d ", vim.v.lnum)
end

-- statuscolumn click handler: revert the hunk whose ">>" is on the clicked line
function _G.GitDiffClick()
	local pos = vim.fn.getmousepos()
	if state and pos.winid == state.left_win and pos.wincol <= 4 then
		local i = state.sign_lines[pos.line]
		if i then
			M.revert_hunk(i)
		end
	end
end

-- Put hunk i's old lines back into the right pane.
function M.revert_hunk(i)
	local h = state and state.hunks[i]
	if not h then
		return
	end
	local start_a, count_a, start_b, count_b = h[1], h[2], h[3], h[4]
	local old = count_a > 0 and vim.list_slice(state.base, start_a, start_a + count_a - 1) or {}
	if count_b == 0 then
		-- lines were deleted: re-insert them after line start_b
		vim.api.nvim_buf_set_lines(state.right_buf, start_b, start_b, false, old)
	else
		vim.api.nvim_buf_set_lines(state.right_buf, start_b - 1, start_b - 1 + count_b, false, old)
	end
	update_hunks()
	vim.api.nvim_win_call(state.right_win, function()
		vim.cmd("diffupdate")
	end)
end

function M.close()
	if not state then
		return
	end
	local s = state
	state = nil
	vim.api.nvim_clear_autocmds({ group = group })
	if valid(s.right_win) then
		vim.api.nvim_win_call(s.right_win, function()
			vim.cmd("diffoff")
		end)
		vim.wo[s.right_win].winbar = ""
	end
	if valid(s.left_win) then
		vim.api.nvim_win_close(s.left_win, true)
	end
end

-- The old version of path to compare against: lines and a label.
local function base_version(path)
	local entries, root = git.status(path)
	local e = entries[1]
	if not e or e.x == "?" or (e.x == "A" and e.y == " ") then
		return {}, "new file"
	end
	local rev, label = ":", "Index"
	if e.y == " " then
		rev, label = "HEAD:", "HEAD"
	end
	if e.x == "A" then
		-- added then edited: the staged version is the base
		rev, label = ":", "Index"
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

local function pane_opts(win)
	vim.wo[win].foldenable = false -- show the whole file, like VS Code
	vim.wo[win].wrap = false
end

-- Open (or switch the open diff to) path.
function M.open(path)
	local base, label = base_version(path)
	local rel = vim.fn.fnamemodify(path, ":~:.")

	-- right: the file itself, in a code window
	switching = true
	local right_buf = vim.fn.bufadd(path)
	vim.bo[right_buf].buflisted = true
	local right_win = state and valid(state.right_win) and state.right_win or nil
	if right_win then
		vim.api.nvim_win_set_buf(right_win, right_buf)
		vim.api.nvim_set_current_win(right_win)
	else
		right_win = require("editor-win").show(right_buf)
	end

	-- left: the old version, in a scratch buffer
	local left_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, base)
	vim.bo[left_buf].modifiable = false
	vim.bo[left_buf].bufhidden = "wipe"
	vim.bo[left_buf].filetype = vim.filetype.match({ filename = path }) or ""
	vim.keymap.set("n", "q", M.close, { buffer = left_buf, desc = "Close the git diff" })

	local left_win = state and valid(state.left_win) and state.left_win or nil
	if left_win then
		vim.api.nvim_win_set_buf(left_win, left_buf)
	else
		left_win = vim.api.nvim_open_win(left_buf, false, { split = "left", win = right_win })
		local total = vim.api.nvim_win_get_width(left_win) + vim.api.nvim_win_get_width(right_win) + 1
		vim.api.nvim_win_set_width(left_win, math.floor(total / 2))
	end
	pcall(vim.api.nvim_buf_set_name, left_buf, "git://" .. label .. "/" .. rel)
	switching = false

	vim.api.nvim_clear_autocmds({ group = group })
	state = {
		path = path,
		left_win = left_win,
		right_win = right_win,
		left_buf = left_buf,
		right_buf = right_buf,
		base = base,
		hunks = {},
		sign_lines = {},
	}

	for _, win in ipairs({ left_win, right_win }) do
		vim.api.nvim_win_call(win, function()
			vim.cmd("diffoff | diffthis")
		end)
		pane_opts(win)
	end
	vim.wo[left_win].number = true
	vim.wo[left_win].relativenumber = false
	vim.wo[left_win].signcolumn = "no"
	vim.wo[left_win].statuscolumn = "%{%v:lua.GitDiffStatuscol()%}"
	vim.wo[left_win].winbar = "%#WinBar# " .. rel .. "  (" .. label .. ", read-only)"
	vim.wo[right_win].winbar = "%#WinBar# " .. rel .. "  (working tree)"
	update_hunks()

	-- keep the hunks current while editing
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWritePost" }, {
		group = group,
		buffer = right_buf,
		callback = update_hunks,
	})
	-- tear down when either pane closes or the right pane moves to another file
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		callback = function(args)
			local win = tonumber(args.match)
			if state and (win == state.left_win or win == state.right_win) then
				vim.schedule(M.close)
			end
		end,
	})
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = group,
		callback = function()
			if not switching and state and vim.api.nvim_get_current_win() == state.right_win
				and vim.api.nvim_get_current_buf() ~= state.right_buf
			then
				vim.schedule(M.close)
			end
		end,
	})
end

-- After staging / discarding: reload the open diff (the base may change).
function M.refresh()
	if not state then
		return
	end
	if #git.status(state.path) == 0 then
		-- no changes left (discarded): nothing to compare
		return M.close()
	end
	local cur = vim.api.nvim_get_current_win()
	M.open(state.path)
	if valid(cur) then
		vim.api.nvim_set_current_win(cur)
	end
end

return M
