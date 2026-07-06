local board_mod = require("kanban.board")

describe("kanban.board", function()
  local function new_board()
    return board_mod.new({
      { id = 1, status = "not_started", title = "first", description = "first desc", date = "2025-01-01 00:00" },
      { id = 2, status = "in_progress", title = "second", description = "second desc", date = "2025-01-02 00:00" },
    }, 2)
  end

  describe("add", function()
    it("assigns max_id + 1, increments max_id, and starts with an empty description", function()
      local board = new_board()

      local task = board:add("third")

      assert.equals(3, task.id)
      assert.equals("not_started", task.status)
      assert.equals("third", task.title)
      assert.equals("", task.description)
      assert.equals(3, board:get_max_id())
      assert.equals(3, #board:get_tasks())
    end)
  end)

  describe("update_status", function()
    it("changes only the target task's status", function()
      local board = new_board()

      local ok = board:update_status(1, "done")

      assert.is_true(ok)
      assert.equals("done", board:get_tasks()[1].status)
      assert.equals("in_progress", board:get_tasks()[2].status)
    end)

    it("returns false for an unknown id", function()
      local board = new_board()
      assert.is_false(board:update_status(999, "done"))
    end)
  end)

  describe("rename", function()
    it("changes title without touching id, status, description, or date", function()
      local board = new_board()

      local ok = board:rename(2, "second, revised")

      assert.is_true(ok)
      local task = board:get_tasks()[2]
      assert.equals(2, task.id)
      assert.equals("in_progress", task.status)
      assert.equals("second, revised", task.title)
      assert.equals("second desc", task.description)
      assert.equals("2025-01-02 00:00", task.date)
    end)

    it("returns false for an unknown id", function()
      local board = new_board()
      assert.is_false(board:rename(999, "new title"))
    end)
  end)

  describe("set_description", function()
    it("changes description without touching id, status, title, or date", function()
      local board = new_board()

      local ok = board:set_description(2, "revised desc")

      assert.is_true(ok)
      local task = board:get_tasks()[2]
      assert.equals(2, task.id)
      assert.equals("in_progress", task.status)
      assert.equals("second", task.title)
      assert.equals("revised desc", task.description)
      assert.equals("2025-01-02 00:00", task.date)
    end)

    it("returns false for an unknown id", function()
      local board = new_board()
      assert.is_false(board:set_description(999, "new description"))
    end)
  end)

  describe("delete", function()
    it("removes the task by id without reusing its id", function()
      local board = new_board()

      local ok = board:delete(1)

      assert.is_true(ok)
      assert.equals(1, #board:get_tasks())
      assert.equals(2, board:get_tasks()[1].id)

      local task = board:add("third")
      assert.equals(3, task.id)
    end)

    it("returns false for an unknown id", function()
      local board = new_board()
      assert.is_false(board:delete(999))
    end)
  end)
end)
