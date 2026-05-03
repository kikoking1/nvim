-- Debug Adapter Protocol setup. Wires nvim-dap + dap-ui + virtual text and
-- configures `netcoredbg` for C# / .NET debugging. The adapter itself is
-- installed via Mason (see lua/plugins/lsp-config.lua).

return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", -- required by dap-ui
      "theHamsta/nvim-dap-virtual-text",
    },
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "DAP: Continue / Start" },
      { "<F10>", function() require("dap").step_over() end, desc = "DAP: Step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "DAP: Step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "DAP: Step out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle [B]reakpoint" },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "DAP: Conditional [B]reakpoint",
      },
      { "<leader>dc", function() require("dap").continue() end, desc = "DAP: [C]ontinue" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "DAP: Toggle [R]EPL" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "DAP: [T]erminate" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "DAP: Run [L]ast" },
      { "<leader>du", function() require("dapui").toggle() end, desc = "DAP: Toggle [U]I" },
      {
        "<leader>de",
        function()
          require("dapui").eval(nil, { enter = true })
        end,
        desc = "DAP: [E]val expression",
        mode = { "n", "v" },
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup({
        commented = true,
      })

      -- Custom signs make breakpoints easier to spot than the default red dots.
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual", numhl = "" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticError", linehl = "", numhl = "" })

      -- Open / close the UI alongside the debug session lifecycle.
      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- .NET / C# adapter. netcoredbg is installed via Mason, which puts it on
      -- PATH; fall back to the Mason package directory just in case.
      local netcoredbg = vim.fn.exepath("netcoredbg")
      if netcoredbg == "" then
        netcoredbg = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg"
      end

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg,
        args = { "--interpreter=vscode" },
      }

      -- Find every .csproj under cwd, then keep only the ones that produce a
      -- runnable host (Exe/WinExe, ASP.NET Core Web SDK, or Worker SDK), then
      -- glob the build output for each. Used by `pick_dll` below to drive a
      -- single-keypress launch in multi-project solutions.
      local function find_executable_projects()
        local cwd = vim.fn.getcwd()
        local entries = {}

        for _, csproj in ipairs(vim.fn.glob(cwd .. "/**/*.csproj", false, true)) do
          if not (csproj:match("/bin/") or csproj:match("/obj/") or csproj:match("/node_modules/")) then
            local f = io.open(csproj, "r")
            if f then
              local content = f:read("*a")
              f:close()

              local is_executable = false
              local sdk = content:match('<Project[^>]*Sdk="([^"]+)"') or ""
              if sdk:lower():match("sdk%.web") or sdk:lower():match("sdk%.worker") then
                is_executable = true
              else
                local out = content:match("<OutputType>%s*([%w]+)%s*</OutputType>")
                if out == "Exe" or out == "WinExe" then
                  is_executable = true
                end
              end

              if is_executable then
                local proj_dir = vim.fn.fnamemodify(csproj, ":h")
                local proj_name = vim.fn.fnamemodify(csproj, ":t:r")
                local dll_glob = proj_dir .. "/bin/Debug/net*/" .. proj_name .. ".dll"
                for _, dll in ipairs(vim.fn.glob(dll_glob, false, true)) do
                  table.insert(entries, {
                    dll = dll,
                    project = proj_name,
                    framework = vim.fn.fnamemodify(dll, ":h:t"),
                    relative = vim.fn.fnamemodify(dll, ":."),
                  })
                end
              end
            end
          end
        end

        return entries
      end

      local function manual_prompt()
        return vim.fn.input({
          prompt = "Path to dll: ",
          default = vim.fn.getcwd() .. "/bin/Debug/",
          completion = "file",
        })
      end

      -- nvim-dap accepts a coroutine here for async selection; ui.select goes
      -- through telescope-ui-select so the picker is fuzzy-searchable.
      local function pick_dll()
        local entries = find_executable_projects()

        if #entries == 0 then
          vim.notify(
            "No executable .NET projects with build output found under cwd. Run `dotnet build` first.",
            vim.log.levels.WARN
          )
          return manual_prompt()
        end

        if #entries == 1 then
          return entries[1].dll
        end

        return coroutine.create(function(dap_run_co)
          vim.ui.select(entries, {
            prompt = "Select project to debug",
            format_item = function(item)
              return string.format("%s (%s)  %s", item.project, item.framework, item.relative)
            end,
          }, function(choice)
            coroutine.resume(dap_run_co, choice and choice.dll or nil)
          end)
        end)
      end

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch (netcoredbg)",
          request = "launch",
          program = pick_dll,
          stopAtEntry = false,
        },
        {
          type = "coreclr",
          name = "Attach to process",
          request = "attach",
          processId = require("dap.utils").pick_process,
        },
      }
    end,
  },
}
