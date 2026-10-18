local storage = require("kanban.storage")

local function tree()
  local root = vim.fn.tempname()
  vim.fn.mkdir(root .. "/a/b", "p")
  return root
end

describe("kanban.storage.find_tasklist", function()
  it("finds the nearest .tasklist in a parent directory", function()
    local root = tree()
    vim.fn.writefile({ "#max_id=0" }, root .. "/.tasklist")

    local path, found = storage.find_tasklist(root .. "/a/b", "/unused")

    assert.equals(root .. "/.tasklist", path)
    assert.is_true(found)
  end)

  it("stops at the git root and proposes a new tasklist there", function()
    local root = tree()
    vim.fn.mkdir(root .. "/.git")

    local path, found = storage.find_tasklist(root .. "/a/b", "/unused")

    assert.equals(root .. "/.tasklist", path)
    assert.is_false(found)
  end)

  it("uses the fallback directory outside a repository", function()
    local root = tree()

    local path, found = storage.find_tasklist(root .. "/a/b", root .. "/a")

    assert.equals(root .. "/a/.tasklist", path)
    assert.is_false(found)
  end)
end)
