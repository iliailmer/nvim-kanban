local parser = require("kanban.parser")

describe("kanban.parser", function()
  describe("parse", function()
    it("parses a well-formed tasklist", function()
      local lines = {
        "#max_id=3",
        "1\t🚀 Not Started\tWrite docs\tWrite documentation\t2025-12-26 10:00",
        "2\t⏳ In Progress\tImplement\tImplement feature\t2025-12-26 11:30",
        "3\t✅ Done\tFix bug\tFix the bug\t2025-12-26 09:15",
      }

      local tasks, max_id = parser.parse(lines)

      assert.equals(3, max_id)
      assert.equals(3, #tasks)
      assert.same({
        id = 1,
        status = "not_started",
        title = "Write docs",
        description = "Write documentation",
        date = "2025-12-26 10:00",
      }, tasks[1])
      assert.equals("in_progress", tasks[2].status)
      assert.equals("done", tasks[3].status)
    end)

    it("handles an empty file", function()
      local tasks, max_id = parser.parse({})
      assert.same({}, tasks)
      assert.equals(0, max_id)
    end)

    it("defaults max_id to 0 when the header is missing", function()
      local tasks, max_id = parser.parse({
        "1\t🚀 Not Started\tNo header\tSome text\t2025-12-26 10:00",
      })
      assert.equals(0, max_id)
      assert.equals(1, #tasks)
    end)

    it("skips malformed lines without throwing", function()
      local tasks, max_id = parser.parse({
        "#max_id=1",
        "not a valid line",
        "1\t🚀 Not Started\tValid\tValid task\t2025-12-26 10:00",
      })
      assert.equals(1, #tasks)
      assert.equals("Valid", tasks[1].title)
      assert.equals(1, max_id)
    end)

    it("bumps max_id to the highest task id even if the header understates it", function()
      local tasks, max_id = parser.parse({
        "#max_id=1",
        "5\t✅ Done\tAhead\tSomehow got ahead\t2025-12-26 10:00",
      })
      assert.equals(5, max_id)
      assert.equals(1, #tasks)
    end)

    it("unescapes newlines and backslashes in the description", function()
      local tasks = parser.parse({
        "#max_id=1",
        "1\t🚀 Not Started\tMulti\tline one\\nline two\\\\not a newline\t2025-12-26 10:00",
      })
      assert.equals("line one\nline two\\not a newline", tasks[1].description)
    end)
  end)

  describe("serialize", function()
    it("round-trips through parse", function()
      local original_lines = {
        "#max_id=2",
        "1\t🚀 Not Started\tWrite docs\tWrite documentation\t2025-12-26 10:00",
        "2\t✅ Done\tFix bug\tFix the bug\t2025-12-26 09:15",
      }

      local tasks, max_id = parser.parse(original_lines)
      local serialized = parser.serialize(tasks, max_id)

      assert.same(original_lines, serialized)
    end)

    it("produces the header line even with no tasks", function()
      local lines = parser.serialize({}, 0)
      assert.same({ "#max_id=0" }, lines)
    end)

    it("escapes newlines and backslashes in the description", function()
      local lines = parser.serialize({
        {
          id = 1,
          status = "not_started",
          title = "Multi",
          description = "line one\nline two\\not a newline",
          date = "2025-12-26 10:00",
        },
      }, 1)

      assert.same({
        "#max_id=1",
        "1\t🚀 Not Started\tMulti\tline one\\nline two\\\\not a newline\t2025-12-26 10:00",
      }, lines)
    end)
  end)
end)
