local dap, dapui = require("dap"), require("dapui")

-- Set breakpoint icon
vim.fn.sign_define('DapBreakpoint', { text = '', texthl = 'red', linehl = 'red', numhl = 'red' })

-- Bind nvim-dap-ui to dap events
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Python
local venv_python_path = function()
  local cwd = vim.loop.cwd()
  if vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
    return cwd .. '/.venv/bin/python'
  else
    return 'python'
  end
end

local set_python_dap = function()
  require('dap-python').setup() -- earlier, so I can setup the various defaults ready to be replaced
  require('dap-python').resolve_python = function()
    return venv_python_path()
  end
  dap.configurations.python = {
    {
      type = 'python',
      request = 'launch',
      name = "Launch file",
      program = "${file}",
      pythonPath = venv_python_path()
    },
    {
      type = 'debugpy',
      request = 'launch',
      name = 'Django',
      program = '${workspaceFolder}/manage.py',
      args = {
        'runserver',
      },
      justMyCode = true,
      django = true,
      console = "integratedTerminal",
      pythonPath = venv_python_path()
    },
    {
      type = 'python',
      request = 'attach',
      name = 'Attach remote',
      connect = function()
        return {
          host = 'localhost',
          port = 5678
        }
      end,
    },
    {
      type = 'python',
      request = 'launch',
      name = 'Launch file with arguments',
      program = '${file}',
      args = function()
        local args_string = vim.fn.input('Arguments: ')
        return vim.split(args_string, " +")
      end,
      console = "integratedTerminal",
      pythonPath = venv_python_path()
    }
  }

  dap.adapters.python = {
    type = 'executable',
    command = venv_python_path(),
    args = { '-m', 'debugpy.adapter' }
  }
end

set_python_dap()
vim.api.nvim_create_autocmd({ "DirChanged", "BufEnter" }, {
  callback = function() set_python_dap() end,
})

require("nvim-dap-virtual-text").setup()
require("dapui").setup({
  layouts = {
    {
      elements = {
        {
          id = "scopes",
          size = 0.70
        },
        {
          id = "breakpoints",
          size = 0.10
        },
        {
          id = "stacks",
          size = 0.20
        }
      },
      position = "left",
      size = 50
    },
    {
      elements = {
        {
          id = "repl",
          size = 1
        }
      },
      position = "bottom",
      size = 10
    }
  },
})




dap.adapters.bashdb = {
  type = 'executable',
  command = vim.fn.stdpath("data") .. '/mason/packages/bash-debug-adapter/bash-debug-adapter',
  name = 'bashdb',
}

dap.adapters.cppdbg = {
  name = 'cppdbg',
  type = 'executable',
  command = vim.fn.stdpath('data') .. '/mason/bin/OpenDebugAD7',
}

dap.configurations.sh = {
  {
    type = 'bashdb',
    request = 'launch',
    name = "Launch file",
    showDebugOutput = true,
    pathBashdb = vim.fn.stdpath("data") .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir/bashdb',
    pathBashdbLib = vim.fn.stdpath("data") .. '/mason/packages/bash-debug-adapter/extension/bashdb_dir',
    trace = true,
    file = "${file}",
    program = "${file}",
    cwd = '${workspaceFolder}',
    pathCat = "cat",
    pathBash = "/bin/bash",
    pathMkfifo = "mkfifo",
    pathPkill = "pkill",
    args = {},
    env = {},
    terminalKind = "integrated",
  }
}

dap.configurations.cpp = {
  {
    name = "Launch",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},
    runInTerminal = true,
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'cppdbg',
    request = 'launch',
    MIMode = 'gdb',
    miDebuggerServerAddress = 'localhost:1234',
    miDebuggerPath = '/usr/bin/gdb',
    cwd = '${workspaceFolder}',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    setupCommands = {
      {
        text = '-enable-pretty-printing',
        description = 'enable pretty printing',
        ignoreFailures = false
      },
    },
  },
}

dap.configurations.h = dap.configurations.cpp
dap.configurations.c = dap.configurations.cpp
-- dap.configurations.rust = dap.configurations.cpp
