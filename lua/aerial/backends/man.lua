local backends = require("aerial.backends")
local backend_util = require("aerial.backends.util")
local util = require("aerial.util")

local M = {}

local ft = "man"
M.is_supported = function(bufnr)
  if not vim.tbl_contains(util.get_filetypes(bufnr), ft) then
    return false, "Filetype is not " .. ft
  end
  return true, nil
end

M.fetch_symbols_sync = function(bufnr)
  bufnr = bufnr or 0

  local fn = vim.fn

  local items = {}

  local lnum = fn.nextnonblank(2)
  local last_lnum = fn.line("$") - 1

  while lnum and lnum < last_lnum do
    local line = fn.getline(lnum)

    if line:sub(1, 1) ~= " " then
      -- Section title
      table.insert(items, {
        kind = "Heading1",

        level = 0,
        name = vim.trim(line),

        parent = nil,

        lnum = lnum,
        end_lnum = lnum,

        col = 1,
        end_col = #line,
      })
    end

    lnum = fn.nextnonblank(lnum + 1)
  end

  backends.set_symbols(bufnr, items)
end

M.fetch_symbols = M.fetch_symbols_sync

M.attach = function(bufnr)
  backend_util.add_change_watcher(bufnr, ft)
  M.fetch_symbols(bufnr)
end

M.detach = function(bufnr)
  backend_util.remove_change_watcher(bufnr, ft)
end

return M
