-- ============================================================
--  Git status plugin for yazi
-- ============================================================

-- ---------- 工具函数 ----------

--- 按分隔符分割字符串
local function split_string(str, delimiter)
    local result = {}
    for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

--- 解析 git status -s 的一行，返回 状态码, 文件名
local function parse_status_line(line)
    local first, rest = line:match("^%s*(%S+)%s*(.*)")
    return first, rest
end

-- ---------- 状态颜色与优先级 ----------

--- 根据状态返回对应的颜色代码
local function get_status_color(status)
    if status == nil then
        return "#6cc749"
    elseif status == "M" or status == "MM" then
        return "#ec613f"
    elseif status == "A" or status == "AM" then
        return "#ec613f"
    elseif status == "." then
        return "#ae96ee"
    elseif status == "?" then
        return "#D4BB91"
    elseif status == "R" then
        return "#ec613f"
    elseif status:match("U") then -- 冲突状态统一红色
        return "#ec613f"
    else
        return "#ec613f"
    end
end

-- 状态优先级，数值越大越优先显示
local status_priority = {
    -- 冲突相关（最高优先级）
    UU = 110, UA = 110, UD = 110,
    DU = 110, AU = 110,
    AA = 100, DD = 100,
    -- 普通变更
    M  = 50, MM = 50, A  = 50, AM = 50,
    R  = 50, RM = 50, D  = 50, MD = 50,
    AD = 50, RD = 50, C  = 50, MC = 50,
    -- 未跟踪
    ["?"] = 40,
    -- 忽略
    ["."] = 10,
}

local function get_status_priority(s)
    return status_priority[s] or 0
end

-- ---------- 解析 git status 输出 ----------

--- 将 `git status -s --ignored` 的完整输出转换为文件状态映射表
--- @return file_table   表，键为文件名（或一级目录名），值为优先的状态码
--- @return is_dirty     仓库是否脏
--- @return is_ignore_dir    当前目录是否整体被忽略
--- @return is_untracked_dir 当前目录是否整体未跟踪
local function parse_git_status_output(git_status_str)
    local file_table = {}
    local is_dirty = false
    local is_ignore_dir = false
    local is_untracked_dir = false

    -- 去掉末尾换行
    local lines = split_string(git_status_str:sub(1, -2), "\n")
    for _, line in ipairs(lines) do
        local label, filename = parse_status_line(line)

        -- 规范化状态码
        local norm_status
        if label == "??" then
            norm_status = "?"
            is_dirty = true
        elseif label == "!!" then
            norm_status = "."
        elseif label == "->" then
            norm_status = "R"
            is_dirty = true
        else
            norm_status = label:gsub("%s", "")  -- 去除空格，例如 " M" -> "M"
            is_dirty = true
        end
        local git_status = norm_status

        -- 快速路径：整个目录被忽略或未跟踪（以 "./" 结尾）
        if filename:sub(-2, -1) == "./" then
            if git_status == "." then
                is_ignore_dir = true
                return file_table, is_dirty, is_ignore_dir, is_untracked_dir
            elseif git_status == "?" then
                is_untracked_dir = true
                return file_table, is_dirty, is_ignore_dir, is_untracked_dir
            end
        end

        -- 多级路径：取第一级目录名作为聚合键
        local components = split_string(filename, "/")
        if (components[#components] == "" and #components == 2) or git_status ~= "." then
            filename = components[1]
        end

        -- 优先级判断：只有更高优先级的状态才覆盖已有的
        local existing = file_table[filename]
        if existing then
            if get_status_priority(git_status) > get_status_priority(existing) then
                file_table[filename] = git_status
            end
        else
            file_table[filename] = git_status
        end
    end

    return file_table, is_dirty, is_ignore_dir, is_untracked_dir
end

-- ---------- 状态同步与渲染 ----------

local save_state = ya.sync(function(st, git_branch, git_file_status, git_is_dirty,
                                    git_status_str, is_ignore_dir, is_untracked_dir)
    st.git_branch = git_branch
    st.git_file_status = git_file_status
    st.git_is_dirty = git_is_dirty and "*" or ""
    st.git_status_str = git_status_str
    st.is_ignore_dir = is_ignore_dir
    st.is_untracked_dir = is_untracked_dir
    ui.render()
end)

local clear_git_state = ya.sync(function(st)
    st.git_branch = ""
    st.git_file_status = ""
    st.git_is_dirty = ""
    ui.render()
end)

local function trigger_git_update(path)
    ya.emit("plugin", {"git"})
end

local get_git_root_path = ya.sync(function(st)
    return (st.git_branch ~= nil and st.git_branch ~= "") and cx.active.current.cwd or nil
end)

local refresh_empty_dir = ya.sync(function(st)
    local cwd = cx.active.current.cwd
    local folder = cx.active.current
    if #folder.window == 0 then
        clear_git_state()
        ya.emit("plugin", {"git", ya.quote(tostring(cwd))})
    end
end)

local apply_default_options = ya.sync(function(state, opts)
    if opts ~= nil and opts.show_brach ~= nil then
        state.opt_show_brach = opts.show_brach
    else
        state.opt_show_brach = true
    end
end)

-- ---------- 插件主体 ----------

local M = {}

function M.setup(st, opts)
    apply_default_options(st, opts)

    -- 文件列表行模式：显示 git 状态标记
    local function create_git_linemode(self)
        local f = self._file
        local git_span = ui.Line {}
        if st.git_branch ~= nil and st.git_branch ~= "" then
            local name = f.name:gsub("\r", "?", 1)  -- 处理可能的回车符
            local git_status
            if st.is_ignore_dir then
                git_status = "."
            elseif st.is_untracked_dir then
                git_status = "?"
            elseif st.git_file_status and st.git_file_status[name] then
                git_status = st.git_file_status[name]
            else
                git_status = nil
            end

            local color = get_status_color(git_status)
            if f.is_hovered then
                git_span = git_status and ui.Span(git_status .. " ") or ui.Span("✓ ")
            else
                git_span = git_status and ui.Span(git_status .. " "):fg(color) or ui.Span("✓ "):fg(color)
            end
        end
        return git_span
    end
    Linemode:children_add(create_git_linemode, 8000)

    -- 头部：工作区切换检测
    local function detect_cwd_change(self)
        local cwd = cx.active.current.cwd
        if st.cwd ~= cwd then
            st.cwd = cwd
            clear_git_state()
            ya.emit("plugin", {"git"})
        end
        return ui.Line {}
    end
    Header:children_add(detect_cwd_change, 8000, Header.LEFT)

    -- 头部：显示当前分支名及脏状态
    local function create_git_header(self)
        if st.git_branch and st.git_branch ~= "" then
            return ui.Line { ui.Span(" <" .. st.git_branch .. st.git_is_dirty .. ">"):fg("#f6a6da") }
        end
        return ui.Line {}
    end
    if st.opt_show_brach then
        Header:children_add(create_git_header, 1400, Header.LEFT)
    end

    -- 监听文件删除/移入回收站，刷新空目录状态
    ps.sub("delete", refresh_empty_dir)
    ps.sub("trash", refresh_empty_dir)
end

function M.entry(_, _)
    apply_default_options()  -- 确保选项已初始化

    local git_branch
    local output, _ = Command("git"):arg({"symbolic-ref", "HEAD"}):stdout(Command.PIPED):output()
    output = output.stdout
    if output ~= nil and output ~= "" then
        local parts = split_string(output:sub(1, -2), "refs/heads/")
        git_branch = parts[2]
    elseif get_git_root_path() then
        git_branch = nil  -- 在仓库中但不在任何分支上（detached HEAD）
    else
        return  -- 非 git 仓库，直接返回
    end

    local git_status_str = ""
    local git_file_status = nil
    local result, _ = Command("git"):arg({
        "--no-optional-locks", "-c", "core.quotePath=", "status", "--ignored",
        "-s", "--ignore-submodules=dirty"
    }):stdout(Command.PIPED):output()
    output = result.stdout
    if output ~= nil and output ~= "" then
        git_status_str = output
        local is_dirty, is_ignore_dir, is_untracked_dir
        git_file_status, is_dirty, is_ignore_dir, is_untracked_dir = parse_git_status_output(git_status_str)
        save_state(git_branch, git_file_status, is_dirty, git_status_str, is_ignore_dir, is_untracked_dir)
    else
        -- 没有输出表示干净仓库
        save_state(git_branch, git_file_status, false, git_status_str, false, false)
    end
end

local function fetch_compact(job)
    return ya.co(function()
        local path = get_git_root_path()
        if path then
            trigger_git_update(path)
        end

        -- 逐个上报文件给 runner，标记本批全部处理成功；不报会被判失败并反复重跑
        for _, file in ipairs(job.files) do
            coroutine.yield(file, {})
        end
    end)
end

function M:fetch(job)
    return fetch_compact(job)
end

return M
