USER = vim.fn.expand("$USER")
HOME = vim.fn.expand("$HOME")
PID = vim.fn.getpid()
local utils = require("nvim-config.utils")
local lspconfig = require("lspconfig")
-- local lspsaga_codeaction = require("lspsaga.codeaction")
-- local root_pattern = lspconfig.util.root_pattern

local M = {}

local diagnostic_signs = {
  error = "",
  warn = "",
  hint = "",
  info = ""
}

local local_settings

function M.get_local_settings()
  if local_settings then return local_settings end

  if utils.file_readable(".vim/lsp-settings.lua") then
    local code_chunk = loadfile(".vim/lsp-settings.lua")
    if code_chunk then
      local_settings = code_chunk()
    end
  else
    local_settings = {}
  end

  return local_settings
end

---@diagnostic disable-next-line: unused-local
vim.lsp.util.apply_text_document_edit = function(text_document_edit, index)
  local text_document = text_document_edit.textDocument
  local bufnr = vim.uri_to_bufnr(text_document.uri)

  vim.lsp.util.apply_text_edits(text_document_edit.edits, bufnr)
end

---@diagnostic disable-next-line: unused-local
_G.LspDefaultOnAttach = function(client, bufnr)
  require("lsp_signature").on_attach({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    handler_opts = {
      border = "single",
    },
  }, bufnr)
end

_G.LspGetDefaultSetup = function()
  return vim.tbl_deep_extend("force", {
    on_attach = LspDefaultOnAttach,
  }, M.get_local_settings())
end

-- Java
require'nvim-config.lsp.java'

-- Typescript
lspconfig.tsserver.setup(LspGetDefaultSetup())

-- Python
lspconfig.pyright.setup(LspGetDefaultSetup())

-- Lua
require'nvim-config.lsp.lua'

-- Teal
require'nvim-config.lsp.teal'

-- C#
require'lspconfig'.omnisharp.setup({
    cmd = { "/usr/bin/omnisharp", "--languageserver" , "--hostPID", tostring(PID) },
    filetypes = { "cs", "vb" },
    init_options = {},
    on_attach = LspDefaultOnAttach,
    -- root_dir = lspconfig.util.root_pattern(".csproj", ".sln"),
    -- root_dir = vim.fn.getcwd
  })

-- C, C++
require'lspconfig'.clangd.setup(LspGetDefaultSetup())

-- Vim
require'lspconfig'.vimls.setup(LspGetDefaultSetup())

-- Go
require'lspconfig'.gopls.setup(LspGetDefaultSetup())

vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
  vim.lsp.diagnostic.on_publish_diagnostics, {
    virtual_text = false,
    underline = true,
    signs = true,
    update_in_insert = true
  }
)

local pop_opts = { border = "single", max_width = 80 }
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, pop_opts)
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, pop_opts
)

function M.define_diagnostic_signs(opts)
  local group = {
    err_group = {
      highlight = 'LspDiagnosticsSignError',
      sign = opts.error
    },
    warn_group = {
      highlight = 'LspDiagnosticsSignWarning',
      sign = opts.warn
    },
    hint_group = {
      highlight = 'LspDiagnosticsSignHint',
      sign = opts.hint
    },
    infor_group = {
      highlight = 'LspDiagnosticsSignInformation',
      sign = opts.info
    },
  }

  for _,g in pairs(group) do
    vim.fn.sign_define(
    g.highlight,
    { text = g.sign, texthl = g.highlight, linehl = '', numhl = '' }
    )
  end
end

M.define_diagnostic_signs(diagnostic_signs)

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

-- Only show diagnostics if cur line is not the same as last call.
local last_diagnostics_line = nil
function M.show_position_diagnostics()
  local cur_line = vim.api.nvim_eval("line('.')")
  if last_diagnostics_line and last_diagnostics_line == cur_line then
    return
  end
  last_diagnostics_line = cur_line

  vim.lsp.diagnostic.show_position_diagnostics()
end

-- LSP auto commands
vim.api.nvim_exec([[
  augroup init_lsp
    au!
    au ColorScheme * :hi def link LspReferenceText CursorLine
    au ColorScheme * :hi def link LspReferenceRead CursorLine
    au ColorScheme * :hi def link LspReferenceWrite CursorLine
    au CursorHold   * silent! lua LspConfig.highlight_cursor_symbol()
    au CursorHoldI  * silent! lua LspConfig.highlight_cursor_symbol()
    au CursorMoved  * silent! lua LspConfig.highlight_cursor_clear()
    au CursorMovedI * silent! lua LspConfig.highlight_cursor_clear()

    au CursorHold * silent! lua LspConfig.show_position_diagnostics()
  augroup END
  ]], false)

_G.LspConfig = M
return M
