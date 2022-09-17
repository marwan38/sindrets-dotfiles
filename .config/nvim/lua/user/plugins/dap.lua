return function()
  local dap, dapui = require("dap"), require("dapui")
  local home = os.getenv "HOME"

  vim.fn.sign_define("DapBreakpoint", {
    text = "",
    texthl = "LspDiagnosticsSignError",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapBreakpointRejected", {
    text = "",
    texthl = "LspDiagnosticsSignHint",
    linehl = "",
    numhl = "",
  })
  vim.fn.sign_define("DapStopped", {
    text = "",
    texthl = "LspDiagnosticsSignInformation",
    linehl = "DiagnosticUnderlineInfo",
    numhl = "LspDiagnosticsSignInformation",
  })

  -- dap.defaults.fallback.terminal_win_cmd = "50vsplit new"

  -- PHP
  dap.adapters.php = {
    type = "executable",
    command = "node",
    args = { home .. "/git/vscode-php-debug/out/phpDebug.js" },
  }
  dap.configurations.php = {
    {
      name = "Listen for XDebug",
      type = "php",
      request = "launch",
      port = 9003,
      pathMappings = {
        ["/srv/archipro/www/marwan/"] = "${workspaceFolder}/",
      },
      stopOnEntry = false,
      ignore = {
        "**/silverstripe-cache/**/*.php",
        "**/vendor/**/*.php",
      },
      hostname = "0.0.0.0",
    },
    {
      name = "Launch currently open script",
      type = "php",
      request = "launch",
      -- program = "${file}",
      cwd = "${workspaceRoot}",
      port = 9003,
    },
  }

  dap.adapters.node2 = {
    type = "executable",
    command = "node",
    args = { home .. "/git/vscode-node-debug2/out/src/nodeDebug.js" },
  }
  dap.configurations.typescriptreact = {
    {
      name = "Launch",

      type = "node2",
      request = "launch",

      program = "${file}",
      cwd = vim.fn.getcwd(),
      sourceMaps = true,
      protocol = "inspector",
      console = "integratedTerminal",
    },
    {
      -- For this to work you need to make sure the node process is started with the `--inspect` flag.
      name = "Attach to process",
      type = "node2",
      request = "attach",
      processId = require("dap.utils").pick_process,
    },
    {
      name = "Jest watch current file",
      type = "node2",
      request = "launch",
      cwd = vim.fn.getcwd(),
      program = "${workspaceFolder}/node_modules/jest/bin/jest",
      args = {
        "${fileBasename}",
        "--verbose",

        "-i",
        "--no-cache",
        "--watchAll",
      },
      protocol = "inspector",
      console = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
    },
  }

  require("dapui").setup({})
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end
