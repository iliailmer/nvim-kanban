local M = {}

M.STATUSES = { "not_started", "in_progress", "done" }

M.STATUS_LABELS = {
	not_started = "🚀 Not Started",
	in_progress = "⏳ In Progress",
	done = "✅ Done",
}

M.LABEL_TO_STATUS = {}
for status, label in pairs(M.STATUS_LABELS) do
	M.LABEL_TO_STATUS[label] = status
end

local HEADER_PATTERN = "^#max_id=(%d+)$"

--- Parse .tasklist file contents into tasks + max_id.
--- @param lines string[]
--- @return table[] tasks
--- @return number max_id
function M.parse(lines)
	local tasks = {}
	local max_id = 0
	local start_index = 1

	if lines[1] then
		local header_id = lines[1]:match(HEADER_PATTERN)
		if header_id then
			max_id = tonumber(header_id)
			start_index = 2
		else
			vim.notify("kanban: .tasklist missing '#max_id=N' header, defaulting to 0", vim.log.levels.WARN)
		end
	end

	for i = start_index, #lines do
		local line = lines[i]
		if line ~= "" then
			local id_str, label, description, date = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$")
			local id = id_str and tonumber(id_str)
			local status = label and M.LABEL_TO_STATUS[label]

			if id and status and description and date then
				table.insert(tasks, {
					id = id,
					status = status,
					description = description,
					date = date,
				})
				-- Only bump max_id from task ids if header was present (safe to trust file's max_id anchor)
				if (start_index == 2) and (id > max_id) then
					max_id = id
				end
			else
				vim.notify(
					string.format("kanban: skipping malformed .tasklist line %d: %q", i, line),
					vim.log.levels.WARN
				)
			end
		end
	end

	return tasks, max_id
end

--- Serialize tasks + max_id back into .tasklist file lines.
--- @param tasks table[]
--- @param max_id number
--- @return string[] lines
function M.serialize(tasks, max_id)
	local lines = { string.format("#max_id=%d", max_id) }
	for _, task in ipairs(tasks) do
		local label = M.STATUS_LABELS[task.status]
		table.insert(lines, string.format("%d\t%s\t%s\t%s", task.id, label, task.description, task.date))
	end
	return lines
end

return M
