local board_mod = require("kanban.board")

-- A client that behaves like tsk: it returns the saved task, or nil and an
-- error. `fail` makes every call fail, as tsk does on a locked or corrupt file.
local function fake_client(opts)
  local next_id = 3
  return {
    add = function(title)
      if opts.fail then
        return nil, "boom"
      end
      local task = { id = next_id, status = "not_started", title = title, description = "", date = "now" }
      next_id = next_id + 1
      return task
    end,
    update = function(id, fields)
      if opts.fail then
        return nil, "boom"
      end
      return vim.tbl_extend("force", { id = id, status = "not_started", title = "t", description = "", date = "now" }, fields)
    end,
    delete = function(id)
      if opts.fail then
        return nil, "boom"
      end
      return { id = id }
    end,
  }
end

local function new_board(opts)
  return board_mod.new({
    { id = 1, status = "not_started", title = "first", description = "", date = "d" },
    { id = 2, status = "in_progress", title = "second", description = "", date = "d" },
  }, fake_client(opts or {}))
end

describe("kanban.board", function()
  local notify
  before_each(function()
    notify = vim.notify
    vim.notify = function() end
  end)
  after_each(function()
    vim.notify = notify
  end)

  it("applies each change that tsk saved", function()
    local board = new_board()

    assert.equals(3, board:add("third").id)
    assert.is_true(board:update_status(1, "done"))
    assert.is_true(board:rename(2, "renamed"))
    assert.is_true(board:delete(1))

    local tasks = board:get_tasks()
    assert.equals(2, #tasks)
    assert.equals("renamed", tasks[1].title)
    assert.equals("third", tasks[2].title)
  end)

  it("keeps the board unchanged when tsk fails", function()
    local board = new_board({ fail = true })

    assert.is_nil(board:add("third"))
    assert.is_false(board:update_status(1, "done"))
    assert.is_false(board:delete(2))

    local tasks = board:get_tasks()
    assert.equals(2, #tasks)
    assert.equals("not_started", tasks[1].status)
  end)

  it("returns false for an unknown id", function()
    assert.is_false(new_board():update_status(999, "done"))
    assert.is_false(new_board():delete(999))
  end)
end)
