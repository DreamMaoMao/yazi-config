-- cmd.yazi
-- 通用外部命令执行器，兼容交互式程序和 fzf 式输出捕获。
--
-- 用法：
--   plugin cmd -- fish             交互模式：stdout 直接继承终端，
--                                  适合 fish/bash/lazygit 等全屏或交互程序
--   plugin cmd -- fzf --pipe       捕获模式：stdout 走管道（原 fzf 风格），
--                                  结束后把输出当作路径执行 cd / reveal
--
-- 无论哪种模式，命令结束后都会刷新 git 状态和目录大小。

local state = ya.sync(function() return cx.active.current.cwd end)

local function fail(s, ...)
	ya.notify { title = "Cmd", content = string.format(s, ...), timeout = 5, level = "error" }
end

local function parse(args)
	local pipe, cmd = false, nil
	for _, a in ipairs(args) do
		if a == "--pipe" then
			pipe = true
		elseif cmd == nil then
			cmd = a
		end
	end
	return cmd, pipe
end

local function entry(_, job)
	local cmd, pipe = parse(job.args)
	if not cmd or cmd == "" then
		return fail("Miss Command")
	end

	local _permit = ui.hide()
	local cwd = tostring(state())

	local child, err =
		Command(cmd):cwd(cwd):stdin(Command.INHERIT):stdout(pipe and Command.PIPED or Command.INHERIT):stderr(Command.INHERIT):spawn()

	if not child then
		return fail("Spawn `%s` failed with error code %s. Do you have it installed?", cmd, err)
	end

	if pipe then
		local output, err = child:wait_with_output()
		if not output then
			return fail("Cannot read `%s` output, error code %s", cmd, err)
		elseif not output.status.success and output.status.code ~= 130 then
			return fail("`%s` exited with error code %s", cmd, output.status.code)
		end

		local target = output.stdout:gsub("\n$", "")
		if target ~= "" then
			ya.emit(target:find("[/\\]$") and "cd" or "reveal", { target })
		end
	else
		-- 交互模式：stdout 已继承终端，只等待退出即可；
		-- shell 的退出码是最后一条命令的结果，不弹错误提示
		child:wait()
	end

	-- 外部命令（如 lazygit）可能只改动 .git 内部状态，文件 hash 不变时
	-- fetch 钩子不会触发，这里主动刷新一次 git 状态
	ya.emit("plugin", { "git" })

	-- 同理，外部命令也可能改动了目录里的文件，主动重算一次目录大小
	ya.emit("plugin", { "current-size", ya.quote(cwd) })
end

return { entry = entry }

