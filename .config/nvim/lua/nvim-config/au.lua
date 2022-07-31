--[
-- Auto command callbacks etc.
--]
local utils = Config.common.utils
local pl = utils.pl
local api = vim.api

local M = {}

local last_sourced_config = nil
local last_sourced_session = nil

function M.source_project_config()
  for _, file in ipairs({ ".vim/init.vim", ".vim/init.lua" }) do
    if utils.pl:readable(file) then
      local project_config_path = utils.pl:realpath(file)
      if last_sourced_config ~= project_config_path then
        vim.cmd("source " .. file)
        last_sourced_config = project_config_path
        utils.info(
          "Sourced project config: "
            .. utils.str_quote(vim.fn.fnamemodify(project_config_path, ":.")),
          true
        )
        break
      end
    end
  end
end

function M.source_project_session()
  if #vim.v.argv == 1 and utils.pl:readable(".vim/Session.vim") then
    local project_config_path = utils.pl:realpath(".vim/Session.vim")
    if last_sourced_session ~= project_config_path then
      vim.cmd("source .vim/Session.vim")
      last_sourced_session = project_config_path
    end
  end
end

---Open a file at a specific line + column.
---Example location: `foo/bar/baz:128:17`
---@param location string
function M.open_file_location(location)
  local bufnr = vim.fn.expand("<abuf>")
  if bufnr == "" then
    return
  end

  bufnr = tonumber(bufnr)
  local l = vim.trim(location)
  local file = utils.str_match(l, { "(.*):%d+:%d+:?$", "(.*):%d+:?$", "(.*):$" })
  local line = tonumber(utils.str_match(l, { ".*:(%d+):%d+:?$", ".*:(%d+):?$" }))
  local col = tonumber(l:match(".*:%d+:(%d+):?$")) or 1

  if pl:readable(file) then
    vim.cmd("keepalt edit " .. vim.fn.fnameescape(file))
    if line then
      api.nvim_exec_autocmds("BufRead", {})
      utils.set_cursor(0, line, col - 1)
      pcall(api.nvim_buf_delete, bufnr, {})
      pcall(api.nvim_exec, "argd " .. vim.fn.fnameescape(l), false)
    end
  end
end

return M
