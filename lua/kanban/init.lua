local M = {}

local storage = require("kanban.storage")
local tsk = require("kanban.tsk")
local board_mod = require("kanban.board")
local ui = require("kanban.ui")

local function start_directory()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" and vim.bo.buftype == "" then
    return vim.fn.fnamemodify(bufname, ":p:h")
  end
  return vim.fn.getcwd()
end

local function report(err)
  vim.notify("kanban: " .. tostring(err), vim.log.levels.ERROR)
end

local function open_path(path)
  local tasks, err = tsk.list(path)
  if not tasks then
    report(err)
    return
  end
  local client = {
    add = function(title)
      return tsk.add(path, title)
    end,
    update = function(id, fields)
      return tsk.update(path, id, fields)
    end,
    delete = function(id)
      return tsk.delete(path, id)
    end,
  }
  ui.open(board_mod.new(tasks, client))
end

function M.open()
  local ok, err = tsk.check_version()
  if not ok then
    report(err)
    return
  end

  local path, found = storage.find_tasklist(start_directory(), vim.fn.getcwd())
  if found then
    open_path(path)
    return
  end

  vim.ui.select({ "No", "Yes" }, { prompt = "No .tasklist found. Create " .. path .. "?" }, function(choice)
    if choice ~= "Yes" then
      return
    end
    local created, init_err = tsk.init(path)
    if not created then
      report(init_err)
      return
    end
    open_path(path)
  end)
end

--- @param opts table|nil { tsk: string|nil } the tsk command, default "tsk"
function M.setup(opts)
  opts = opts or {}
  tsk.configure({ cmd = opts.tsk })
  vim.api.nvim_create_user_command("Kanban", function()
    M.open()
  end, {})
end

return M
