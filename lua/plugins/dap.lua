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

      -- Auto-detects bin/Debug/net*/<project>.dll. If there's exactly one
      -- match we use it; otherwise we prompt with completion.
      local function pick_dll()
        local cwd = vim.fn.getcwd()
        local matches = vim.fn.glob(cwd .. "/bin/Debug/net*/*.dll", false, true)
        if #matches == 1 then
          return matches[1]
        end
        return vim.fn.input({
          prompt = "Path to dll: ",
          default = cwd .. "/bin/Debug/",
          completion = "file",
        })
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
