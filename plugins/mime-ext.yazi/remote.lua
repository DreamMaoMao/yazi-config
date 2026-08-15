--- @since 26.5.6
local M = {}

local function stale_cache(file)
	local url = file.url
	local cache = url.spec and (url.spec.stamp or url.spec.cache) or url.scheme.cache -- TODO: remove
	local lock = cache:join(string.format("%%lock/%s", url:hash(true)))

	local f = io.open(tostring(lock), "r")
	if not f then
		return true
	end

	local hash = f:read(32)
	f:close()
	return hash ~= file.cha:hash(true)
end

function M:fetch(job)
	return ya.co(function()
		local unknown, updates = {}, {}
		for _, file in ipairs(job.files) do
			if file.cha.is_dummy then
				coroutine.yield(file, {})
			elseif not file.cache then
				unknown[#unknown + 1] = file
			elseif not fs.cha(Url(file.cache)) then
				updates[file.url] = coroutine.yield(file, { "vfs/absent" }) and "vfs/absent" or nil
			elseif stale_cache(file) then
				updates[file.url] = coroutine.yield(file, { "vfs/stale" }) and "vfs/stale" or nil
			else
				unknown[#unknown + 1] = file
			end
		end

		require("mime.dir").commit(updates)
		if #unknown > 0 then
			self.fallback_local(job, unknown)
		end
	end)
end

function M.fallback_local(job, unknown)
	local next = require(".local"):fetch(ya.dict_merge(job, { files = unknown }))
	local file, result = next()
	while file do
		file, result = next(coroutine.yield(file, result))
	end
end

return M
