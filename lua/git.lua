-- Git operations for the Git view of neo-tree (lua/plugins/neo-tree.lua):
-- stage / unstage and discard a file or folder.

local M = {}

local function run(args, cwd)
	local res = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
	return res.code == 0, vim.trim(res.stdout or ""), vim.trim(res.stderr or "")
end

-- Repo root containing path (a file or folder, which may have been deleted).
function M.root(path)
	local dir = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
	while vim.fn.isdirectory(dir) == 0 do
		dir = vim.fs.dirname(dir)
	end
	local ok, out = run({ "rev-parse", "--show-toplevel" }, dir)
	return ok and out or nil
end

-- Changed files at or under path: list of { x, y, path, orig? } where x / y
-- are the index / working tree status letters of `git status --porcelain`
-- ("?" for untracked) and paths are absolute.
function M.status(path)
	local root = M.root(path)
	if not root then
		return {}, nil
	end
	local res = vim.system(
		{ "git", "status", "--porcelain=v1", "-z", "--untracked-files=all", "--", path },
		{ cwd = root, text = true }
	):wait()
	local entries, fields = {}, vim.split(res.stdout or "", "\0", { plain = true })
	local i = 1
	while i <= #fields do
		local f = fields[i]
		if #f > 3 then
			local entry = { x = f:sub(1, 1), y = f:sub(2, 2), path = root .. "/" .. f:sub(4) }
			if entry.x == "R" or entry.x == "C" then
				-- renames / copies are followed by the original path
				i = i + 1
				entry.orig = root .. "/" .. fields[i]
			end
			table.insert(entries, entry)
		end
		i = i + 1
	end
	return entries, root
end

-- Whether path has anything left to stage (vs. everything already staged).
function M.has_unstaged(entries)
	for _, e in ipairs(entries) do
		if e.y ~= " " then
			return true
		end
	end
	return false
end

-- Reload buffers changed on disk and redraw neo-tree and any open git diff.
local function refresh()
	vim.cmd("checktime")
	pcall(function()
		require("neo-tree.sources.manager").refresh("git_status")
		require("neo-tree.sources.manager").refresh("filesystem")
	end)
	require("git-diff").refresh()
end

-- Stage path if it has unstaged changes, else unstage it.
function M.toggle_stage(path)
	local entries, root = M.status(path)
	if #entries == 0 then
		return vim.notify("No changes in " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
	end
	local ok, _, err
	if M.has_unstaged(entries) then
		ok, _, err = run({ "add", "-A", "--", path }, root)
	elseif run({ "rev-parse", "--verify", "--quiet", "HEAD" }, root) then
		ok, _, err = run({ "restore", "--staged", "--", path }, root)
	else
		-- no commits yet: there's no HEAD to restore the index from
		ok, _, err = run({ "rm", "--cached", "-r", "-q", "--", path }, root)
	end
	if not ok then
		vim.notify(err, vim.log.levels.ERROR)
	end
	refresh()
end

-- Delete a file, then any folders above it that are left empty.
local function delete_file(file, root)
	vim.fn.delete(file)
	local dir = vim.fs.dirname(file)
	while dir ~= root and vim.fn.delete(dir, "d") == 0 do
		dir = vim.fs.dirname(dir)
	end
end

-- Throw away all changes (staged or not) to path, after asking. Files git
-- doesn't have in HEAD (untracked or newly added) are deleted.
function M.discard(path)
	local entries, root = M.status(path)
	if #entries == 0 then
		return vim.notify("No changes in " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO)
	end
	local name = vim.fn.fnamemodify(path, ":t")
	local question = #entries == 1 and entries[1].x == "?"
			and string.format('Delete untracked file "%s"?', name)
		or string.format('Discard all changes in "%s"? This can\'t be undone.', name)
	-- Enter picks the default, Yes
	if vim.fn.confirm(question, "&Yes\n&No", 1, "Question") ~= 1 then
		return
	end

	for _, e in ipairs(entries) do
		if e.x == "?" then
			delete_file(e.path, root)
		elseif e.x == "A" or e.x == "R" or e.x == "C" then
			-- not in HEAD: unstage and delete; a rename also gets its original back
			run({ "rm", "--cached", "-f", "-q", "--", e.path }, root)
			delete_file(e.path, root)
			if e.x == "R" then
				run({ "restore", "--source=HEAD", "--staged", "--worktree", "--", e.orig }, root)
			end
		else
			local ok, _, err = run({ "restore", "--source=HEAD", "--staged", "--worktree", "--", e.path }, root)
			if not ok then
				vim.notify(err, vim.log.levels.ERROR)
			end
		end
	end
	refresh()
end

return M
