local M = {}

local Board = {}
Board.__index = Board

--- @param tasks table[]
--- @param max_id number
--- @return table board
function M.new(tasks, max_id)
  return setmetatable({
    tasks = tasks,
    max_id = max_id,
  }, Board)
end

function Board:get_tasks()
  return self.tasks
end

function Board:get_max_id()
  return self.max_id
end

local function find_index(tasks, id)
  for i, task in ipairs(tasks) do
    if task.id == id then
      return i
    end
  end
  return nil
end

--- @param description string
--- @return table task
function Board:add(description)
  self.max_id = self.max_id + 1
  local task = {
    id = self.max_id,
    status = "not_started",
    description = description,
    date = os.date("%Y-%m-%d %H:%M"),
  }
  table.insert(self.tasks, task)
  return task
end

--- @param id number
--- @param status string
--- @return boolean ok
function Board:update_status(id, status)
  local index = find_index(self.tasks, id)
  if not index then
    return false
  end
  self.tasks[index].status = status
  return true
end

--- @param id number
--- @param description string
--- @return boolean ok
function Board:edit(id, description)
  local index = find_index(self.tasks, id)
  if not index then
    return false
  end
  self.tasks[index].description = description
  return true
end

--- @param id number
--- @return boolean ok
function Board:delete(id)
  local index = find_index(self.tasks, id)
  if not index then
    return false
  end
  table.remove(self.tasks, index)
  return true
end

return M
