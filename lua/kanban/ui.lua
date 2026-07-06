local M = {}

local parser = require("kanban.parser")

local COLUMN_STATUSES = { "not_started", "in_progress", "done" }

local state = {
  board = nil,
  on_change = nil,
  wins = {},
  bufs = {},
  line_ids = {},
  focus = 1,
}

local detail_state = {
  win = nil,
  buf = nil,
  task_id = nil,
  return_win = nil,
}

local editor_state = {
  win = nil,
  buf = nil,
  task_id = nil,
}

local function tasks_by_status(status)
  local result = {}
  for _, task in ipairs(state.board:get_tasks()) do
    if task.status == status then
      table.insert(result, task)
    end
  end
  return result
end

local function render_column(col_index)
  local status = COLUMN_STATUSES[col_index]
  local tasks = tasks_by_status(status)
  local buf = state.bufs[col_index]
  local lines = {}
  local line_ids = {}

  for _, task in ipairs(tasks) do
    table.insert(lines, string.format("[%d] %s", task.id, task.title))
    line_ids[#lines] = task.id
  end

  if #lines == 0 then
    lines = { "  (empty)" }
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  state.line_ids[col_index] = line_ids
end

local function render()
  for col_index = 1, #COLUMN_STATUSES do
    render_column(col_index)
  end
end

local function persist()
  if state.on_change then
    state.on_change()
  end
end

local function current_column_index()
  local current_win = vim.api.nvim_get_current_win()
  for col_index, win in pairs(state.wins) do
    if win == current_win and vim.api.nvim_win_is_valid(win) then
      return col_index
    end
  end
  return nil
end

local function current_task_id()
  local col_index = current_column_index()
  if not col_index then
    return nil
  end
  local win = state.wins[col_index]
  if not win or not vim.api.nvim_win_is_valid(win) then
    return nil
  end
  local line = vim.api.nvim_win_get_cursor(win)[1]
  return state.line_ids[col_index][line]
end

local function find_task(id)
  for _, task in ipairs(state.board:get_tasks()) do
    if task.id == id then
      return task
    end
  end
  return nil
end

local function focus_column(col_index)
  if col_index < 1 or col_index > #COLUMN_STATUSES then
    return
  end
  local win = state.wins[col_index]
  if win and vim.api.nvim_win_is_valid(win) then
    state.focus = col_index
    vim.api.nvim_set_current_win(win)
  end
end

local function move_focused_card(delta)
  local col_index = current_column_index()
  if not col_index then
    return
  end
  local id = current_task_id()
  if not id then
    return
  end
  local target_index = col_index + delta
  if target_index < 1 or target_index > #COLUMN_STATUSES then
    return
  end
  state.board:update_status(id, COLUMN_STATUSES[target_index])
  persist()
  render()
  focus_column(target_index)
end

local function add_card()
  vim.ui.input({ prompt = "New task title: " }, function(title)
    if title == nil or title == "" then
      return
    end
    state.board:add(title)
    persist()
    render()
  end)
end

local function rename_card()
  local id = current_task_id()
  if not id then
    return
  end
  local task = find_task(id)
  vim.ui.input({ prompt = "Title: ", default = task.title }, function(title)
    if title == nil or title == "" then
      return
    end
    state.board:rename(id, title)
    persist()
    render()
  end)
end

local function delete_card()
  local id = current_task_id()
  if not id then
    return
  end
  vim.ui.select({ "No", "Yes" }, { prompt = "Delete task " .. id .. "?" }, function(choice)
    if choice == "Yes" then
      state.board:delete(id)
      persist()
      render()
    end
  end)
end

local function close()
  for _, win in pairs(state.wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  state.wins = {}
  state.bufs = {}
  state.line_ids = {}
end

-- ## Card detail view + description editor
--
-- Pressing <CR> on a card opens a read-only "detail" floating window showing
-- its title and full (possibly multi-line) description. From there, `r`
-- renames the title and `e` opens the description in an editable scratch
-- buffer (real multi-line editing, since vim.ui.input is single-line only).

local function render_detail()
  local task = find_task(detail_state.task_id)
  if not task then
    return
  end
  local lines = { "Title: " .. task.title, "", "Description:" }
  for _, line in ipairs(vim.split(task.description, "\n", { plain = true })) do
    table.insert(lines, line)
  end
  vim.bo[detail_state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(detail_state.buf, 0, -1, false, lines)
  vim.bo[detail_state.buf].modifiable = false
end

local function close_detail()
  if detail_state.win and vim.api.nvim_win_is_valid(detail_state.win) then
    vim.api.nvim_win_close(detail_state.win, true)
  end
  local return_win = detail_state.return_win
  detail_state.win = nil
  detail_state.buf = nil
  detail_state.task_id = nil
  detail_state.return_win = nil
  if return_win and vim.api.nvim_win_is_valid(return_win) then
    vim.api.nvim_set_current_win(return_win)
  end
end

local function detail_rename()
  local task = find_task(detail_state.task_id)
  if not task then
    return
  end
  local task_id = detail_state.task_id
  vim.ui.input({ prompt = "Title: ", default = task.title }, function(title)
    if title == nil or title == "" then
      return
    end
    state.board:rename(task_id, title)
    persist()
    render()
    render_detail()
  end)
end

local function close_editor()
  if editor_state.win and vim.api.nvim_win_is_valid(editor_state.win) then
    vim.api.nvim_win_close(editor_state.win, true)
  end
  editor_state.win = nil
  editor_state.buf = nil
  editor_state.task_id = nil
  if detail_state.win and vim.api.nvim_win_is_valid(detail_state.win) then
    vim.api.nvim_set_current_win(detail_state.win)
  end
end

local function open_description_editor()
  local task = find_task(detail_state.task_id)
  if not task then
    return
  end
  local task_id = detail_state.task_id

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.5)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Edit Description (<C-s> save, q/Esc discard)",
    title_pos = "center",
  })

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(task.description, "\n", { plain = true }))
  vim.bo[buf].modifiable = true

  editor_state.win = win
  editor_state.buf = buf
  editor_state.task_id = task_id

  local function save_and_close()
    local lines = vim.api.nvim_buf_get_lines(editor_state.buf, 0, -1, false)
    local description = table.concat(lines, "\n")
    local id = editor_state.task_id
    close_editor()
    state.board:set_description(id, description)
    persist()
    render()
    render_detail()
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set({ "n", "i" }, "<C-s>", function()
    vim.cmd("stopinsert")
    save_and_close()
  end, opts)
  vim.keymap.set("n", "q", close_editor, opts)
  vim.keymap.set("n", "<Esc>", close_editor, opts)
end

local function open_detail()
  local id = current_task_id()
  if not id then
    return
  end
  local origin_win = vim.api.nvim_get_current_win()

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "Card Detail (r rename, e edit description, q/Esc close)",
    title_pos = "center",
  })

  detail_state.win = win
  detail_state.buf = buf
  detail_state.task_id = id
  detail_state.return_win = origin_win

  render_detail()

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "r", detail_rename, opts)
  vim.keymap.set("n", "e", open_description_editor, opts)
  vim.keymap.set("n", "q", close_detail, opts)
  vim.keymap.set("n", "<Esc>", close_detail, opts)
end

local function set_keymaps(buf)
  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "h", function()
    local col_index = current_column_index()
    if col_index then
      focus_column(col_index - 1)
    end
  end, opts)
  vim.keymap.set("n", "l", function()
    local col_index = current_column_index()
    if col_index then
      focus_column(col_index + 1)
    end
  end, opts)
  vim.keymap.set("n", "H", function() move_focused_card(-1) end, opts)
  vim.keymap.set("n", "L", function() move_focused_card(1) end, opts)
  vim.keymap.set("n", "n", add_card, opts)
  vim.keymap.set("n", "r", rename_card, opts)
  vim.keymap.set("n", "d", delete_card, opts)
  vim.keymap.set("n", "<CR>", open_detail, opts)
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
end

--- @param board table a kanban.board instance
--- @param opts table { on_change: function() }
function M.open(board, opts)
  if editor_state.win and vim.api.nvim_win_is_valid(editor_state.win) then
    vim.api.nvim_win_close(editor_state.win, true)
  end
  editor_state.win, editor_state.buf, editor_state.task_id = nil, nil, nil

  if detail_state.win and vim.api.nvim_win_is_valid(detail_state.win) then
    vim.api.nvim_win_close(detail_state.win, true)
  end
  detail_state.win, detail_state.buf, detail_state.task_id, detail_state.return_win = nil, nil, nil, nil

  if next(state.wins) then
    close()
  end

  state.board = board
  state.on_change = opts and opts.on_change
  state.focus = 1

  local columns = #COLUMN_STATUSES
  local total_width = math.floor(vim.o.columns * 0.9)
  local col_width = math.floor(total_width / columns)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col_start = math.floor((vim.o.columns - total_width) / 2)

  for col_index = 1, columns do
    local status = COLUMN_STATUSES[col_index]
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"

    local win = vim.api.nvim_open_win(buf, col_index == 1, {
      relative = "editor",
      width = col_width - 1,
      height = height,
      row = row,
      col = col_start + (col_index - 1) * col_width,
      style = "minimal",
      border = "rounded",
      title = parser.STATUS_LABELS[status],
      title_pos = "center",
    })

    state.bufs[col_index] = buf
    state.wins[col_index] = win
    set_keymaps(buf)
  end

  render()
end

return M
