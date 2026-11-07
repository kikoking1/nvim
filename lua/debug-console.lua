-- Debug view of the bottom panel (lua/panel.lua), replacing nvim-dap-ui: one
-- console with the output of every nvim-dap session (plus the build output
-- from lua/dotnet.lua), and Continue / Pause / Step / Restart / Stop buttons
-- in the winbar.

local panel = require("panel")

local M = {}

local buf, chan = nil, nil
local status = nil -- shown instead of the session state, e.g. while building
-- Set by M.start: stop() cancels a build, restart() relaunches (rebuilding).
local hooks = {}

local function dap()
	-- don't load nvim-dap just to draw the winbar
	return package.loaded["dap"] and require("dap")
end

local function ensure_buf()
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		buf = vim.api.nvim_create_buf(false, true)
		vim.bo[buf].bufhidden = "hide"
		chan = vim.api.nvim_open_term(buf, {})
	end
	return buf
end

local function redraw()
	vim.schedule(function()
		vim.cmd("redrawstatus!")
	end)
end

function M.write(text)
	ensure_buf()
	pcall(vim.api.nvim_chan_send, chan, (text:gsub("\r?\n", "\r\n")))
end

local function write_dim(text)
	M.write("\27[90m" .. text .. "\27[0m")
end

function M.set_status(text)
	status = text
	redraw()
end

function M.open(opts)
	panel.show("debug", opts)
end

-- Start a fresh console for a new launch: ends any running session and clears
-- the output. hooks = { stop = fn?, restart = fn? }.
function M.start(new_hooks)
	local d = dap()
	if d and d.session() then
		d.terminate()
	end
	hooks = new_hooks or {}
	-- swap in a new buffer before deleting the old one, so the panel window
	-- isn't closed along with it
	local old = buf
	buf = nil
	M.open({ focus = false })
	if old and vim.api.nvim_buf_is_valid(old) then
		vim.api.nvim_buf_delete(old, { force = true })
	end
end

local actions = {
	function() -- continue / start
		require("dap").continue()
	end,
	function()
		require("dap").pause()
	end,
	function()
		require("dap").step_over()
	end,
	function()
		require("dap").step_into()
	end,
	function()
		require("dap").step_out()
	end,
	function()
		local d = require("dap")
		if hooks.restart then
			hooks.restart()
		elseif d.session() then
			d.restart()
		else
			d.run_last()
		end
	end,
	function()
		local d = dap()
		if d and d.session() then
			d.terminate()
		end
		if hooks.stop then
			hooks.stop()
		end
	end,
}

function _G.DebugConsoleButton(id)
	actions[id]()
	redraw()
end

function _G.DebugConsoleWinbar()
	local d = dap()
	local session = d and d.session()
	local stopped = session and session.stopped_thread_id ~= nil
	local running = session and not stopped

	-- color: suffix of the PanelIcon* highlight for the icon (lua/panel.lua)
	local function button(id, icon, label, color, enabled)
		local icon_hl = enabled and "%#PanelIcon" .. color .. "#" or "%#PanelButtonOff#"
		local label_hl = enabled and "%#PanelButton#" or "%#PanelButtonOff#"
		return string.format("%%%d@v:lua.DebugConsoleButton@%s %s %s%s %%X", id, icon_hl, icon, label_hl, label)
	end

	local bar = {
		running and button(2, "", "Pause F5", "Pause", true) -- nf-cod-debug_pause
			or button(1, "", session and "Continue F5" or "Start F5", "Continue", true), -- nf-cod-debug_continue
		button(3, "", "Step over F10", "Step", stopped), -- nf-cod-debug_step_over
		button(4, "", "Step into F11", "Step", stopped), -- nf-cod-debug_step_into
		button(5, "", "Step out F12", "Step", stopped), -- nf-cod-debug_step_out
		button(6, "", "Restart", "Restart", session or hooks.restart), -- nf-cod-debug_restart
		button(7, "", "Stop", "Stop", session or hooks.stop), -- nf-cod-debug_stop
	}

	local state = status
	if not state then
		if stopped then
			local frame = session.current_frame
			state = "Paused"
			if frame and frame.source and frame.source.path then
				state = state .. " · " .. vim.fn.fnamemodify(frame.source.path, ":t") .. ":" .. frame.line
			end
		elseif running then
			state = "Running · " .. session.config.name
		else
			state = "No debug session"
		end
	end
	-- %< : in a narrow window, cut the status text rather than the buttons
	return " " .. table.concat(bar, "%#PanelBar#  ") .. "%#PanelBar#%<%=" .. state .. " "
end

-- Hook into nvim-dap. Called from lua/plugins/dap.lua once nvim-dap loads.
function M.attach(d)
	local key = "debug_console"
	local function on(kind, name, fn)
		d.listeners[kind][name][key] = fn
	end

	local function started(session)
		status = nil
		write_dim("── " .. session.config.name .. " ──\n")
		M.open({ focus = false })
		redraw()
	end
	on("before", "launch", started)
	on("before", "attach", started)

	on("after", "event_output", function(_, body)
		-- With a debugger attached, Microsoft.Extensions.Logging's Debug
		-- provider repeats every log line through Debugger.Log (those events
		-- carry a source), as "Category: Level: message". The console logger
		-- already printed them, so skip the copies. Other Debugger.Log output,
		-- like Debug.WriteLine, still shows.
		if body.source and body.output:match("^[%w%.`]+: %a+: ") then
			return
		end
		if body.category == "stdout" or body.category == "stderr" then
			M.write(body.output)
		elseif body.category ~= "telemetry" then
			write_dim(body.output)
		end
	end)
	on("after", "event_exited", function(_, body)
		write_dim("\n[process exited " .. tostring(body.exitCode) .. "]\n")
	end)
	on("after", "event_terminated", function()
		write_dim("── session ended ──\n")
		redraw()
	end)

	for _, name in ipairs({ "event_stopped", "event_continued", "event_initialized" }) do
		on("after", name, redraw)
	end
	for _, name in ipairs({ "continue", "next", "stepIn", "stepOut", "pause", "disconnect", "terminate" }) do
		on("after", name, redraw)
	end
end

panel.register("debug", {
	icon = "", -- nf-cod-bug
	winbar = "%{%v:lua.DebugConsoleWinbar()%}",
	buf = ensure_buf,
	open = M.open,
})

return M
