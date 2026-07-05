local M = {}

local storage = require("kanban.storage")
local parser = require("kanban.parser")
local board_mod = require("kanban.board")
local ui = require("kanban.ui")

local function start_directory()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname ~= "" then
    return vim.fn.fnamemodify(bufname, ":p:h")
  end
  return vim.fn.getcwd()
end

local function open_path(path)
  local lines = storage.read_file(path)
  local tasks, max_id = parser.parse(lines)
  local board = board_mod.new(tasks, max_id)

  ui.open(board, {
    on_change = function()
      local ok, err = storage.write_file(
        path,
        parser.serialize(board:get_tasks(), board:get_max_id())
      )
      if not ok then
        vim.notify("kanban: failed to save .tasklist: " .. tostring(err), vim.log.levels.ERROR)
      end
    end,
  })
end

function M.open()
  local path = storage.find_tasklist(start_directory())

  if path then
    open_path(path)
    return
  end

  local cwd = vim.fn.getcwd()

  vim.ui.select({ "No", "Yes" }, {
    prompt = "No .tasklist found. Create one in " .. cwd .. "?",
  }, function(choice)
    if choice ~= "Yes" then
      return
    end
    local new_path = cwd .. "/.tasklist"
    local ok, err = storage.write_file(new_path, { "#max_id=0" })
    if not ok then
      vim.notify("kanban: failed to create .tasklist: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    open_path(new_path)
  end)
end

--- @param opts table|nil
function M.setup(opts)
  opts = opts or {}
  vim.api.nvim_create_user_command("Kanban", function()
    M.open()
  end, {})
end

return M
