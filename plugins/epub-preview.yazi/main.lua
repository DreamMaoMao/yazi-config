local M = {}

local function clean_desc(s)
	s = s:gsub("%s+", " ")
	s = s:gsub("&amp;", "&")
	s = s:gsub("&lt;", "<")
	s = s:gsub("&gt;", ">")
	s = s:gsub("&quot;", '"')
	s = s:gsub("&#39;", "'")
	s = s:gsub("<[^>]+>", "")
	return s:match("^%s*(.-)%s*$") or ""
end

local function read_file(p)
	local f = io.open(p, "rb")
	if not f then
		return nil
	end
	local s = f:read("*a")
	f:close()
	return s
end

-- Parse the book description from the OPF.
function M:parse_desc(job)
	local path = tostring(job.file.path or job.file.url)

	local container = Command("unzip"):arg { "-p", path, "META-INF/container.xml" }:output()
	if not container or not container.status.success then
		return ""
	end

	local opf = container.stdout:match('full%-path="([^"]+)"')
	if not opf then
		return ""
	end

	local output = Command("unzip"):arg { "-p", path, opf }:output()
	if not output or not output.status.success then
		return ""
	end

	local desc = output.stdout:match("<dc:description>(.-)</dc:description>")
		or output.stdout:match("<description>(.-)</description>")
	return desc and clean_desc(desc) or ""
end

-- Read the description, cached as a file in Yazi's cache directory.
function M:description(job, cache)
	local desc_path = tostring(cache) .. ".desc"
	local desc = read_file(desc_path)
	if desc == nil then
		desc = self:parse_desc(job)
		if desc ~= "" then
			fs.write(Url(desc_path), desc)
		end
	end
	return desc ~= "" and desc or nil
end

function M:peek(job)
	local cache = ya.file_cache(job)
	if not cache then
		return
	end

	local desc = self:description(job, cache)
	local area = job.area
	local width = math.max(1, area.w)
	local limit = math.max(1, area.h)

	local content = {}
	if desc then
		for _, line in ipairs(ui.lines(desc, {
			ansi = false,
			tab_size = rt.preview.tab_size,
			wrap = ui.Wrap.YES,
			width = width,
		})) do
			content[#content + 1] = line
		end
	end

	if #content == 0 then
		ya.preview_widget(job, {})
		return
	end

	local max_skip = math.max(0, #content - limit)
	if job.skip > max_skip then
		ya.emit("peek", { max_skip, only_if = job.file.url, upper_bound = true })
		return
	end

	local visible = {}
	for i = job.skip + 1, math.min(#content, job.skip + limit) do
		visible[#visible + 1] = content[i]
	end
	ya.preview_widget(job, ui.Text(visible):area(area))
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.emit("peek", {
			math.max(0, cx.active.preview.skip + job.units),
			only_if = job.file.url,
		})
	end
end

return M
