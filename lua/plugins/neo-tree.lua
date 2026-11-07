-- Directory the node lives in: the node itself for folders, its parent for files.
local function node_dir(node)
	if node.type == "directory" then
		return node:get_id()
	end
	return node:get_parent_id()
end

local function telescope_grep(state)
	local path = node_dir(state.tree:get_node())
	require("telescope.builtin").live_grep({
		search_dirs = { path },
		prompt_title = string.format("Grep in [%s]", vim.fn.fnamemodify(path, ":t")),
	})
end

local function telescope_find(state)
	local path = node_dir(state.tree:get_node())
	require("telescope.builtin").find_files({
		search_dirs = { path },
		prompt_title = string.format("Find in [%s]", vim.fn.fnamemodify(path, ":t")),
	})
end

-- A mapped right-click doesn't move the cursor, so move it to the clicked
-- line, then return the node there.
local function node_at_mouse(state)
	local pos = vim.fn.getmousepos()
	if pos.winid ~= 0 and pos.line > 0 then
		vim.api.nvim_set_current_win(pos.winid)
		vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 0 })
	end
	return state.tree:get_node()
end

-- items: list of { label, fn }
local function show_menu(node, items)
	vim.ui.select(items, {
		prompt = vim.fn.fnamemodify(node:get_id(), ":t"),
		format_item = function(item)
			return item[1]
		end,
	}, function(choice)
		if choice then
			choice[2]()
		end
	end)
end

local function context_menu(state)
	local node = node_at_mouse(state)
	if not node then
		return
	end
	local cmds = require("neo-tree.sources.filesystem.commands")
	local function cmd(name)
		return function()
			cmds[name](state)
		end
	end

	local items
	if node.type == "directory" then
		items = {}
		local dotnet = require("dotnet")
		local project = dotnet.find_project(node:get_id())
		if project then
			table.insert(items, { "Run .NET project", function() dotnet.run(project) end })
			table.insert(items, { "Debug .NET project", function() dotnet.debug(project) end })
		end
		vim.list_extend(items, {
			{ "New file", cmd("add") },
			{ "New folder", cmd("add_directory") },
			{ "Find in folder", function() telescope_find(state) end },
			{ "Grep in folder", function() telescope_grep(state) end },
			{ "Rename", cmd("rename") },
			{ "Paste", cmd("paste_from_clipboard") },
			{ "Delete", cmd("delete") },
		})
	else
		items = {
			{ "Open", cmd("open") },
			{ "Open in split", cmd("open_split") },
			{ "Open in vsplit", cmd("open_vsplit") },
			{ "Rename", cmd("rename") },
			{ "Copy", cmd("copy_to_clipboard") },
			{ "Cut", cmd("cut_to_clipboard") },
			{ "Delete", cmd("delete") },
		}
	end
	show_menu(node, items)
end

-- Git view (the git_status source, opened from the activity bar).

-- Files open as a side-by-side diff (lua/git-diff.lua); folders expand.
local function git_open_diff(state)
	local node = state.tree:get_node()
	if node.type == "file" then
		require("git-diff").open(node:get_id())
	else
		require("neo-tree.sources.common.commands").toggle_node(state)
	end
end

local function git_toggle_stage(state)
	require("git").toggle_stage(state.tree:get_node():get_id())
end

local function git_discard(state)
	require("git").discard(state.tree:get_node():get_id())
end

local function git_context_menu(state)
	local node = node_at_mouse(state)
	if not node then
		return
	end
	local git = require("git")
	local path = node:get_id()
	local kind = node.type == "file" and "File" or "Folder"
	local items = {}
	if node.type == "file" then
		table.insert(items, { "Open Changes", function() require("git-diff").open(path) end })
		table.insert(items, {
			"Open File",
			function()
				require("editor-win").show(vim.fn.bufadd(path))
			end,
		})
	end
	local staging = git.has_unstaged((git.status(path)))
	table.insert(items, {
		(staging and "Stage " or "Unstage ") .. kind .. "  (s)",
		function() git.toggle_stage(path) end,
	})
	table.insert(items, { "Discard Changes  (d)", function() git.discard(path) end })
	show_menu(node, items)
end

return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	cmd = "Neotree",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	keys = {
		{ "<leader>nn", "<cmd>Neotree toggle left<cr>", desc = "[N]eotree [T]oggle" },
		{ "<leader>nf", "<cmd>Neotree reveal<cr>", desc = "[N]eotree reveal current [F]ile" },
	},
	opts = {
		filesystem = {
			window = {
				mappings = {
					-- Mapping "fg" to our custom grep command below
					["fg"] = "telescope_grep",
					-- Mapping "ff" to our custom find files command below
					["ff"] = "telescope_find",
					["<RightMouse>"] = "context_menu",
				},
			},
			commands = {
				telescope_grep = telescope_grep,
				telescope_find = telescope_find,
				context_menu = context_menu,
			},
		},
		git_status = {
			window = {
				mappings = {
					["<cr>"] = "git_open_diff",
					["<2-LeftMouse>"] = "git_open_diff",
					["s"] = "git_toggle_stage",
					["d"] = "git_discard",
					["<RightMouse>"] = "git_context_menu",
				},
			},
			commands = {
				git_open_diff = git_open_diff,
				git_toggle_stage = git_toggle_stage,
				git_discard = git_discard,
				git_context_menu = git_context_menu,
			},
		},
		-- Files / Git activity bar to the left of the tree (lua/activity-bar.lua)
		event_handlers = {
			{
				event = "neo_tree_window_after_open",
				handler = function(args)
					if args.position == "left" then
						require("activity-bar").attach(args.winid, args.source)
					end
				end,
			},
			{
				event = "neo_tree_window_before_close",
				handler = function(args)
					if args.position == "left" then
						require("activity-bar").detach()
					end
				end,
			},
		},
	},
}
