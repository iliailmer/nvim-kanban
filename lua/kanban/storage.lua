local M = {}

local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

--- Search upward from start_dir for an existing .tasklist file.
--- Stops after checking the filesystem root or $HOME, whichever comes first.
--- @param start_dir string
--- @return string|nil path
function M.find_tasklist(start_dir)
  local dir = vim.fn.fnamemodify(start_dir, ":p:h")
  local home = vim.loop.os_homedir()

  while true do
    local candidate = dir .. "/.tasklist"
    if file_exists(candidate) then
      return candidate
    end

    if dir == "/" or dir == home then
      return nil
    end

    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      return nil
    end
    dir = parent
  end
end

--- Read a file's lines. Returns an empty table if the file does not exist.
--- @param path string
--- @return string[] lines
function M.read_file(path)
  if not file_exists(path) then
    return {}
  end
  return vim.fn.readfile(path)
end

--- Atomically write lines to path: write to a temp file, then rename.
--- @param path string
--- @param lines string[]
--- @return boolean ok
--- @return string|nil err
function M.write_file(path, lines)
  local tmp_path = path .. ".tmp"
  local write_result = vim.fn.writefile(lines, tmp_path)
  if write_result ~= 0 then
    return false, "failed to write temp file " .. tmp_path
  end

  local rename_ok, rename_err = os.rename(tmp_path, path)
  if not rename_ok then
    return false, rename_err or ("failed to rename " .. tmp_path .. " to " .. path)
  end

  return true, nil
end

return M
