-- Run / debug a .NET project in the bottom panel (lua/panel.lua): runs go to
-- a terminal tab, debug sessions to the debug view. Used by the neo-tree
-- right-click menu.

local M = {}

-- First *.csproj / *.fsproj directly inside dir, or nil.
function M.find_project(dir)
	for _, pattern in ipairs({ "*.csproj", "*.fsproj" }) do
		local match = vim.fn.glob(dir .. "/" .. pattern, false, true)[1]
		if match then
			return match
		end
	end
end

-- Tabs are keyed by project, so re-running restarts it; the tab stays open
-- after exit to keep the output.
function M.run(project)
	require("terminal-tabs").run("dotnet run --project " .. vim.fn.shellescape(project), {
		name = "run " .. vim.fn.fnamemodify(project, ":t:r"),
		cwd = vim.fn.fnamemodify(project, ":h"),
		key = "dotnet:" .. project,
	})
end

-- Environment `dotnet run` would use: the first "Project" profile in
-- Properties/launchSettings.json (env vars and applicationUrl).
local function launch_env(dir)
	local f = io.open(dir .. "/Properties/launchSettings.json", "r")
	if not f then
		return nil
	end
	-- the dotnet templates write this file with a UTF-8 BOM, which the JSON
	-- decoder rejects
	local text = f:read("*a"):gsub("^\239\187\191", "")
	f:close()
	local ok, settings = pcall(vim.json.decode, text)
	if not ok or type(settings) ~= "table" or type(settings.profiles) ~= "table" then
		vim.notify("Couldn't read Properties/launchSettings.json, using defaults", vim.log.levels.WARN)
		return nil
	end
	-- decoded objects lose their key order, so find the first profile by its
	-- position in the file (like `dotnet run` does)
	local first, first_pos
	for name, profile in pairs(settings.profiles) do
		local pos = text:find(vim.json.encode(name) .. "%s*:")
		if profile.commandName == "Project" and pos and (not first_pos or pos < first_pos) then
			first, first_pos = profile, pos
		end
	end
	if first then
		local env = vim.deepcopy(first.environmentVariables or {})
		if first.applicationUrl then
			env.ASPNETCORE_URLS = first.applicationUrl
		end
		return env
	end
end

-- Build the project, then launch it under netcoredbg (see lua/plugins/dap.lua)
-- so breakpoints are hit. The build output and the app's output go to the
-- debug view of the bottom panel (lua/debug-console.lua), whose Stop button
-- cancels the build and whose Restart button rebuilds. netcoredbg starts the
-- app itself, so the app's stdin isn't connected.
function M.debug(project)
	local console = require("debug-console")
	local name = vim.fn.fnamemodify(project, ":t:r")
	local dir = vim.fn.fnamemodify(project, ":h")
	local build, cancelled = nil, false

	local function write_async(_, data)
		if data then
			vim.schedule(function()
				console.write(data)
			end)
		end
	end

	console.start({
		stop = function()
			cancelled = true
			if build then
				build:kill("sigterm")
			end
		end,
		restart = function()
			M.debug(project)
		end,
	})
	console.set_status("Building " .. name)
	console.write("$ dotnet build " .. vim.fn.fnamemodify(project, ":.") .. "\n")

	build = vim.system({ "dotnet", "build", project }, { cwd = dir, stdout = write_async, stderr = write_async }, function(res)
		build = nil
		if cancelled or res.code ~= 0 then
			vim.schedule(function()
				console.set_status(nil)
				console.write(cancelled and "\n[build cancelled]\n" or "\n[build failed]\n")
			end)
			return
		end
		vim.system({ "dotnet", "msbuild", project, "-getProperty:TargetPath" }, { cwd = dir }, vim.schedule_wrap(function(target)
			local dll = vim.trim(target.stdout or "")
			if cancelled or target.code ~= 0 or dll == "" then
				console.set_status(nil)
				if not cancelled then
					console.write("\n[couldn't find the build output for " .. name .. "]\n")
				end
				return
			end
			console.write("\n")
			require("dap").run({
				type = "coreclr",
				request = "launch",
				name = "Debug " .. name,
				program = dll,
				cwd = dir,
				env = launch_env(dir),
				stopAtEntry = false,
			})
		end))
	end)
end

return M
