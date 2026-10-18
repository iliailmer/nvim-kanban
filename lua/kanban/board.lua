local M = {}

local Board = {}
Board.__index = Board

--- @param tasks table[] tasks as returned by `tsk show --json`
--- @param client table { add, update, delete } bound to one tasklist
--- @return table board
function M.new(tasks, client)
  return setmetatable({ tasks = tasks, client = client }, Board)
end

function Board:get_tasks()
  return self.tasks
end

local function find_index(tasks, id)
  for i, task in ipairs(tasks) do
    if task.id == id then
      return i
    end
  end
  return nil
end

local function report(err)
  vim.notify("kanban: " .. tostring(err), vim.log.levels.ERROR)
end

-- Each change goes through tsk first. The local copy changes only when tsk
-- saved the change, so the board never shows something that is not on disk.
function Board:apply(id, fields)
  local index = find_index(self.tasks, id)
  if not index then
    return false
  end
  local task, err = self.client.update(id, fields)
  if not task then
    report(err)
    return false
  end
  self.tasks[index] = task
  return true
end

--- @param title string
--- @return table|nil task
function Board:add(title)
  local task, err = self.client.add(title)
  if not task then
    report(err)
    return nil
  end
  table.insert(self.tasks, task)
  return task
end

function Board:update_status(id, status)
  return self:apply(id, { status = status })
end

function Board:rename(id, title)
  return self:apply(id, { title = title })
end

function Board:set_description(id, description)
  return self:apply(id, { description = description })
end

function Board:delete(id)
  local index = find_index(self.tasks, id)
  if not index then
    return false
  end
  local _, err = self.client.delete(id)
  if err then
    report(err)
    return false
  end
  table.remove(self.tasks, index)
  return true
end

return M
