-- Runs the real tsk binary: set TSK_BIN to choose one (default: tsk on PATH).
local tsk = require("kanban.tsk")

describe("kanban.tsk", function()
  before_each(function()
    tsk.configure({ cmd = os.getenv("TSK_BIN") })
  end)

  it("needs tsk 0.3.0 or newer", function()
    local ok, err = tsk.check_version()
    assert.is_true(ok, err)
  end)

  it("runs the full task lifecycle through tsk", function()
    local path = vim.fn.tempname() .. ".tasklist"
    assert.is_true((tsk.init(path)))
    assert.same({}, tsk.list(path))

    local task = assert(tsk.add(path, "-starts with a dash"))
    assert.equals(1, task.id)
    assert.equals("-starts with a dash", task.title)

    local updated = assert(tsk.update(path, 1, { status = "done", description = "line 1\nline 2" }))
    assert.equals("done", updated.status)
    assert.equals("line 1\nline 2", updated.description)
    assert.same({ updated }, tsk.list(path))

    assert(tsk.delete(path, 1))
    assert.same({}, tsk.list(path))
  end)

  it("returns the tsk error message", function()
    local path = vim.fn.tempname() .. ".tasklist"
    assert(tsk.init(path))

    local task, err = tsk.delete(path, 9)

    assert.is_nil(task)
    assert.equals("Task with ID 9 not found", err)
  end)
end)
