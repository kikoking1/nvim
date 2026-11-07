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

-- First *.csproj / *.fsproj directly inside dir, or nil.
local function find_dotnet_project(dir)
	for _, pattern in ipairs({ "*.csproj", "*.fsproj" }) do
		local match = vim.fn.glob(dir .. "/" .. pattern, false, true)[1]
		if match then
			return match
		end
	end
end

-- One terminal per project; re-running restarts it.
local dotnet_terms = {}

local function dotnet_run(project)
	if dotnet_terms[project] then
		dotnet_terms[project]:shutdown()
	end
	local term = require("toggleterm.terminal").Terminal:new({
		cmd = "dotnet run --project " .. vim.fn.shellescape(project),
		dir = vim.fn.fnamemodify(project, ":h"),
		direction = "horizontal",
		display_name = "dotnet run " .. vim.fn.fnamemodify(project, ":t:r"),
		-- keep the output visible after the app exits or crashes
		close_on_exit = false,
	})
	dotnet_terms[project] = term
	term:open()
end

local function context_menu(state)
	-- a mapped right-click doesn't move the cursor, so do it here
	local pos = vim.fn.getmousepos()
	if pos.winid ~= 0 and pos.line > 0 then
		vim.api.nvim_set_current_win(pos.winid)
		vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 0 })
	end

	local node = state.tree:get_node()
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
		local project = find_dotnet_project(node:get_id())
		if project then
			table.insert(items, { "Run .NET project", function() dotnet_run(project) end })
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
	},
}
