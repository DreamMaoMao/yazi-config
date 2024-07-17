local function string_split(input,delimiter)

	local result = {}

	for match in (input..delimiter):gmatch("(.-)"..delimiter) do
	        table.insert(result, match)
	end
	return result
end

local save = ya.sync(function(st, cwd,folder_size)
	if cx.active.current.cwd == Url(cwd) then
		st.folder_size = folder_size
		ya.render()
	end
end)

local clear_state = ya.sync(function(st)
	st.folder_size = ""
	ya.render()
end)


local set_opts_default = ya.sync(function(state)
	if (state.opt_folder_size_ignore == nil) then
		state.opt_folder_size_ignore = {}
	end
end)

local function update_current_size(files)
	local filemane = tostring((files[1]).url)
	local str = filemane:sub(-1,-1) == "/" and filemane:sub(1,-2) or filemane
	local pattern = "(.+)/[^/]+$"
	local pwd = string.match(str, pattern)
	ya.manager_emit("plugin", { "current-size", args = ya.quote(tostring(pwd))})	
end

local M = {
	setup = function(st,opts)

		set_opts_default()

		if (opts ~= nil and opts.folder_size_ignore ~= nil ) then
			st.opt_folder_size_ignore  = opts.folder_size_ignore
		end
		
		local function header_size(self)
			local cwd = cx.active.current.cwd
			local ignore_caculate_size = false

			for _, value in ipairs(st.opt_folder_size_ignore) do
				if value == tostring(cwd) then
					ignore_caculate_size = true
				end
			end

			local folder_size_span = (st.folder_size ~= nil and st.folder_size ~= "") and ui.Span(" [".. st.folder_size  .."]"):fg("#ced333")  or {}
			if st.cwd ~= cwd then
				st.cwd = cwd
				clear_state()
				ya.manager_emit("plugin", { "current-size", args = ya.quote(tostring(cwd)).." "..tostring(ignore_caculate_size)})			
			end
			return folder_size_span
		end

		Header:children_add(header_size,1500,Header.LEFT)

	end,

	entry = function(_, args)
		local output


		local folder_size = ""
		if args[2] ~= "true" then
			output = Command("du"):args({"-sh",args[1].."/"}):output()
		else
			output = nil
		end
		if output then
			local split_output = string_split(output.stdout,"\t")
			folder_size = split_output[1]
		end		

		save(args[1],folder_size)
	end,
}

function M:fetch()
	update_current_size(self.files)	
	return 3	
end

return M