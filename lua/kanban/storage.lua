local M = {}

local function exists(path)
  return vim.loop.fs_stat(path) ~= nil
end

--- Find the tasklist the same way `tsk` does: the nearest `.tasklist` in
--- start_dir or above it, stopping at the git repository root.
--- @param start_dir string
--- @param fallback_dir string where a new tasklist goes outside a repository
--- @return string path
--- @return boolean found
function M.find_tasklist(start_dir, fallback_dir)
  local dir = vim.fn.fnamemodify(start_dir, ":p"):gsub("/$", "")
  if dir == "" then
    dir = "/"
  end

  while true do
    local candidate = (dir == "/" and "" or dir) .. "/.tasklist"
    if exists(candidate) then
      return candidate, true
    end
    if exists(dir .. "/.git") then
      return candidate, false
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then
      break
    end
    dir = parent
  end

  return vim.fn.fnamemodify(fallback_dir, ":p"):gsub("/$", "") .. "/.tasklist", false
end

return M
