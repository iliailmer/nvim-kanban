local M = {}

M.MIN_VERSION = { 0, 3, 0 }

local config = { cmd = "tsk" }

--- @param opts table { cmd: string|nil }
function M.configure(opts)
  config.cmd = opts.cmd or "tsk"
end

local function run(args)
  local cmd = { config.cmd }
  vim.list_extend(cmd, args)
  local ok, result = pcall(function()
    return vim.system(cmd, { text = true }):wait()
  end)
  if not ok then
    return nil, "cannot run " .. config.cmd .. ": " .. tostring(result)
  end
  if result.code ~= 0 then
    local message = vim.trim(result.stderr ~= "" and result.stderr or result.stdout)
    return nil, (message:gsub("^Error: ", ""))
  end
  return result.stdout, nil
end

local function run_json(path, args)
  local out, err = run(vim.list_extend({ "--file", path }, args))
  if not out then
    return nil, err
  end
  local ok, value = pcall(vim.json.decode, out)
  if not ok then
    return nil, "unexpected output from " .. config.cmd .. ": " .. out
  end
  return value, nil
end

--- @return boolean ok
--- @return string|nil err
function M.check_version()
  local out, err = run({ "--version" })
  if not out then
    return false, err
  end
  local version = { out:match("(%d+)%.(%d+)%.(%d+)") }
  if #version ~= 3 then
    return false, "cannot read the version from: " .. vim.trim(out)
  end
  for i = 1, 3 do
    local have, need = tonumber(version[i]), M.MIN_VERSION[i]
    if have ~= need then
      if have > need then
        return true, nil
      end
      return false, string.format("tsk %s found, %s or newer is required", table.concat(version, "."), table.concat(M.MIN_VERSION, "."))
    end
  end
  return true, nil
end

-- Values are passed as `--flag=value` so that a title starting with "-" is
-- not read as an option.

function M.list(path)
  return run_json(path, { "show", "--json" })
end

function M.add(path, title)
  return run_json(path, { "add", "--title=" .. title, "--json" })
end

--- @param fields table { status: string|nil, title: string|nil, description: string|nil }
function M.update(path, id, fields)
  local args = { "update", tostring(id), "--json" }
  for _, name in ipairs({ "status", "title", "description" }) do
    if fields[name] ~= nil then
      table.insert(args, "--" .. name .. "=" .. fields[name])
    end
  end
  return run_json(path, args)
end

function M.delete(path, id)
  return run_json(path, { "delete", tostring(id), "--json" })
end

function M.init(path)
  local out, err = run({ "--file", path, "init" })
  return out ~= nil, err
end

return M
