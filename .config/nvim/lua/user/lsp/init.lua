local cmp_lsp = require("cmp_nvim_lsp")
local lspconfig = require("lspconfig")

local utils = Config.common.utils
local notify = Config.common.notify
local pl = utils.pl
local config_store = {}

local M = {}
_G.Config.lsp = M

require("lspconfig.ui.windows").default_options.border = "single"

---@diagnostic disable-next-line: unused-local
function M.common_on_attach(client, bufnr)
  -- require("illuminate").on_attach(client)
  require("lsp_signature").on_attach({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    handler_opts = {
      border = "single",
    },
  }, bufnr)
end

M.base_config = {
  on_attach = M.common_on_attach,
  capabilities = utils.tbl_union_extend(
    vim.lsp.protocol.make_client_capabilities(),
    cmp_lsp.default_capabilities()
  ),
}

M.local_config_paths = {
  ".vim/lsp_init.lua",
  ".vim/lsp_settings.lua",
  ".vim/lsprc.lua",
  ".lsprc.lua",
}

function M.create_local_config(config)
  local cwd = uv.cwd()
  local local_config = config_store[cwd]
  local project_config = Config.state.project_config
  config = config or {}

  if not local_config then
    if type(project_config) == "table" and project_config.lsp_config then
      local_config = project_config.lsp_config
      notify.config("Using LSP config from project config.")
    else
      for _, path in ipairs(M.local_config_paths) do
        if pl:readable(path) then
          notify.config("Using project-local LSP config: " .. utils.str_quote(path))
          local code_chunk = loadfile(path)
          if code_chunk then
            local_config = code_chunk()
            break
          end
        end
      end
    end

    if not local_config then
      local_config = {}
    end

    config_store[cwd] = local_config
  end

  if vim.is_callable(local_config) then
    local_config = local_config(config)
  else
    local_config = utils.tbl_union_extend(config, local_config)
  end

  return local_config
end

---Create lsp config from base + server defaults + local config.
---@param ... table Set of LSP configs sorted by order of precedence: later
---configs will overwrite earlier configs.
---@return table
function M.create_config(...)
  local config = utils.tbl_union_extend(M.base_config, {}, ...)

  return M.create_local_config(config)
end

-- Java
-- require("user.lsp.java")

-- Typescript
require("typescript").setup({
    disable_commands = false, -- prevent the plugin from creating Vim commands
    debug = false, -- enable debug logging for commands
    server = { -- pass options to lspconfig's setup method
        on_attach = M.base_config.on_attach,
    },
})

-- Python
-- lspconfig.pyright.setup(M.create_config())

-- Lua
require("user.lsp.lua")

-- Teal
-- require("user.lsp.teal")

-- Bash
lspconfig.bashls.setup(M.create_config())

-- C#
lspconfig.omnisharp.setup(M.create_config({
  cmd = { "/usr/bin/omnisharp", "--languageserver" , "--hostPID", tostring(vim.fn.getpid()) },
  filetypes = { "cs", "vb" },
  init_options = {},
  -- root_dir = lspconfig.util.root_pattern(".csproj", ".sln"),
  -- root_dir = vim.fn.getcwd
}))

-- ESLint
require'lspconfig'.eslint.setup(M.create_config())

-- C, C++
-- lspconfig.clangd.setup(M.create_config())

-- Vim
-- lspconfig.vimls.setup(M.create_config())

-- Go
-- lspconfig.gopls.setup(M.create_config())

-- Scheme, Racket
-- lspconfig.racket_langserver.setup(M.create_config())

-- PHP
lspconfig.intelephense.setup(M.create_config())

-- JSON
require("user.lsp.json")

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    underline = true,
    signs = true,
    update_in_insert = true
  }
)

-- DIAGNOSTICS: Only show the sign with the highest priority per line
-- From: `:h diagnostic-handlers-example`

local ns = vim.api.nvim_create_namespace("user_lsp")
local orig_signs_handler = vim.diagnostic.handlers.signs

-- Override the built-in signs handler
vim.diagnostic.handlers.signs = {
  show = function(_, bufnr, _, opts)
    -- Get all diagnostics from the whole buffer rather than just the
    -- diagnostics passed to the handler
    local diagnostics = vim.diagnostic.get(bufnr)

    -- Find the "worst" diagnostic per line
    local max_severity_per_line = {}
    for _, d in pairs(diagnostics) do
      local m = max_severity_per_line[d.lnum]
      if not m or d.severity < m.severity then
        max_severity_per_line[d.lnum] = d
      end
    end

    -- Pass the filtered diagnostics (with our custom namespace) to
    -- the original handler
    orig_signs_handler.show(ns, bufnr, vim.tbl_values(max_severity_per_line), opts)
  end,
  hide = function(_, bufnr)
    orig_signs_handler.hide(ns, bufnr)
  end,
}

local pop_opts = { border = "single", max_width = 80 }
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, pop_opts)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, pop_opts
)

function M.define_diagnostic_signs(opts)
  local group = {
    -- version 0.5
    {
      highlight = 'LspDiagnosticsSignError',
      sign = opts.error
    },
    {
      highlight = 'LspDiagnosticsSignWarning',
      sign = opts.warn
    },
    {
      highlight = 'LspDiagnosticsSignHint',
      sign = opts.hint
    },
    {
      highlight = 'LspDiagnosticsSignInformation',
      sign = opts.info
    },
    -- version >=0.6
    {
      highlight = 'DiagnosticSignError',
      sign = opts.error
    },
    {
      highlight = 'DiagnosticSignWarn',
      sign = opts.warn
    },
    {
      highlight = 'DiagnosticSignHint',
      sign = opts.hint
    },
    {
      highlight = 'DiagnosticSignInfo',
      sign = opts.info
    },
  }

  for _, g in ipairs(group) do
    vim.fn.sign_define(g.highlight, {
        text = g.sign,
        texthl = g.highlight,
        linehl = '',
        numhl = '',
      }
    )
  end
end

-- Highlight references on cursor hold

function M.highlight_cursor_symbol()
  if vim.lsp.buf.server_ready() then
    if vim.fn.mode() ~= "i" then
      vim.lsp.buf.document_highlight()
    end
  end
end

function M.highlight_cursor_clear()
  if vim.lsp.buf.server_ready() then
    vim.lsp.buf.clear_references()
  end
end
---------------------------------

-- Only show diagnostics if current word + line is not the same as last call.
local last_diagnostics_word = nil
function M.show_position_diagnostics()
  local cword = vim.fn.expand("<cword>")
  local cline = vim.api.nvim_win_get_cursor(0)[1]
  local bufnr = vim.api.nvim_get_current_buf()

  if last_diagnostics_word
    and last_diagnostics_word[1] == cline
    and last_diagnostics_word[2] == cword
    and last_diagnostics_word[3] == bufnr then
    return
  end
  last_diagnostics_word = { cline, cword, bufnr }

  vim.diagnostic.open_float({ scope = "cursor", border = "single" })
end

M.define_diagnostic_signs({
  error = "",
  warn = "",
  hint = "",
  info = ""
})

-- LSP auto commands
Config.common.au.declare_group("lsp_init", {}, {
  { "CursorHold", callback = M.show_position_diagnostics, },
})

return M
