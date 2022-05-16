local backends = require("aerial.backends")
local backend_util = require("aerial.backends.util")
local util = require("aerial.util")

local M = {}

M.is_supported = function(bufnr)
  local ft = "norg"
  if not vim.tbl_contains(util.get_filetypes(bufnr), ft) then
    return false, "Filetype is not " .. ft
  end
  return true, nil
end

M.fetch_symbols_sync = function(bufnr)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
  -- local last_item = nil
  local items = {}
  local stack = {}
  local inside_code_block = false
  local pat = "^%s*(%*+)%s+(.*)$"
  for lnum, line in ipairs(lines) do
    local stars, head = string.match(line, pat)
    if stars and not inside_code_block then
      -- if last_item then
      --   last_item.end_lnum = lnum - 1
      -- end
      --
      local level = #stars - 1
      local parent = stack[math.min(level, #stack)]

      local item = {
        kind = "Heading" .. (level + 1),

        name = vim.trim(head),

        level = level,
        parent = parent,

        lnum = lnum,
        end_lnum = lnum + 2,

        col = 1,
        end_col = #line,
      }
      -- last_item = item

      if parent then
        if not parent.children then
          parent.children = {}
        end
        table.insert(parent.children, item)
      else
        table.insert(items, item)
      end
      while #stack > level and #stack > 0 do
        table.remove(stack, #stack)
      end
      table.insert(stack, item)
    elseif string.match(line, "^%s*@code%s") then
      -- LATER: test nesting `@code`
      inside_code_block = true
    elseif string.match(line, "^%s*@end") then
      if inside_code_block then
        inside_code_block = false
      end
    end
  end
  backends.set_symbols(bufnr, items)
end

M.fetch_symbols = M.fetch_symbols_sync

local name = "neorg"

M.attach = function(bufnr)
  backend_util.add_change_watcher(bufnr, name)
  M.fetch_symbols(bufnr)
end

M.detach = function(bufnr)
  backend_util.remove_change_watcher(bufnr, name)
end

return M
