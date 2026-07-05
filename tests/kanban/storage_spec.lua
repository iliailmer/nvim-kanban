local storage = require("kanban.storage")

local function mkdirp(path)
  vim.fn.mkdir(path, "p")
end

describe("kanban.storage", function()
  describe("find_tasklist", function()
    it("finds .tasklist in the starting directory", function()
      local root = vim.fn.tempname()
      mkdirp(root)
      vim.fn.writefile({ "#max_id=0" }, root .. "/.tasklist")

      local found = storage.find_tasklist(root)

      assert.equals(root .. "/.tasklist", found)
    end)

    it("finds .tasklist in a parent directory from a nested cwd", function()
      local root = vim.fn.tempname()
      local nested = root .. "/a/b/c"
      mkdirp(nested)
      vim.fn.writefile({ "#max_id=0" }, root .. "/.tasklist")

      local found = storage.find_tasklist(nested)

      assert.equals(root .. "/.tasklist", found)
    end)

    it("returns nil when no .tasklist exists up to the search boundary", function()
      local root = vim.fn.tempname()
      local nested = root .. "/x/y"
      mkdirp(nested)

      local found = storage.find_tasklist(nested)

      assert.is_nil(found)
    end)
  end)

  describe("read_file", function()
    it("returns an empty table for a nonexistent file", function()
      local lines = storage.read_file(vim.fn.tempname() .. "/does-not-exist")
      assert.same({}, lines)
    end)

    it("reads existing file lines", function()
      local path = vim.fn.tempname()
      vim.fn.writefile({ "a", "b" }, path)

      local lines = storage.read_file(path)

      assert.same({ "a", "b" }, lines)
    end)
  end)

  describe("write_file", function()
    it("writes lines atomically and leaves no temp file behind", function()
      local path = vim.fn.tempname()

      local ok, err = storage.write_file(path, { "#max_id=0", "1\tstatus\tdesc\tdate" })

      assert.is_true(ok)
      assert.is_nil(err)
      assert.same({ "#max_id=0", "1\tstatus\tdesc\tdate" }, vim.fn.readfile(path))
      assert.equals(0, vim.fn.filereadable(path .. ".tmp"))
    end)
  end)
end)
