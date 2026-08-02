local function string_split(input, delimiter)
    local result = {}
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
        table.insert(result, match)
    end
    return result
end

local function split_label_filename(str)
    local first, rest = str:match "^%s*(%S+)%s*(.*)"
    return first, rest
end

local function set_status_color(status)
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
    elseif status:match("U") then -- 冲突状态统一用红色
        return "#ec613f"
    else
        return "#ec613f"
    end
end

-- 状态优先级映射表，数值越大越优先
local status_priority = {
    -- 冲突相关最高
    UU = 110,
    UA = 110,
    UD = 110,
    DU = 110,
    AU = 110,
    AA = 100,
    DD = 100,
    -- 普通变更
    M = 50,
    MM = 50,
    A = 50,
    AM = 50,
    R = 50,
    RM = 50,
    D = 50,
    MD = 50,
    AD = 50,
    RD = 50,
    C = 50,
    MC = 50,
    -- 未跟踪
    ["?"] = 40,
    -- 忽略
    ["."] = 10
}
local function get_priority(s)
    return status_priority[s] or 0
end

local function make_git_table(git_status_str)
    local file_table = {}
    local git_status
    local is_dirty = false
    local multi_path
    local is_ignore_dir = false
    local is_untracked_dir = false
    local label, filename
    local split_table = string_split(git_status_str:sub(1, -2), "\n")
    for _, value in ipairs(split_table) do
        label, filename = split_label_filename(value)

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
            norm_status = label:gsub("%s", "") -- 去除空格，例如 " M" -> "M"
            is_dirty = true
        end
        git_status = norm_status

        -- 快速路径：整个目录被忽略或未跟踪
        if filename:sub(-2, -1) == "./" and git_status == "." then
            is_ignore_dir = true
            return file_table, is_dirty, is_ignore_dir, is_untracked_dir
        end
        if filename:sub(-2, -1) == "./" and git_status == "?" then
            is_untracked_dir = true
            return file_table, is_dirty, is_ignore_dir, is_untracked_dir
        end

        -- 多级路径只取第一级目录名作为聚合键
        multi_path = string_split(filename, "/")
        if (multi_path[#multi_path] == "" and #multi_path == 2) or git_status ~= "." then
            filename = multi_path[1]
        end

        -- 优先级判断：只有新状态的优先级更高时才覆盖
        local existing = file_table[filename]
        if existing then
            if get_priority(git_status) > get_priority(existing) then
                file_table[filename] = git_status
            end
        else
            file_table[filename] = git_status
        end
    end

    return file_table, is_dirty, is_ignore_dir, is_untracked_dir
end

local save = ya.sync(function(st, git_branch, git_file_status, git_is_dirty, git_status_str, is_ignore_dir,
    is_untracked_dir)
    st.git_branch = git_branch
    st.git_file_status = git_file_status
    st.git_is_dirty = git_is_dirty and "*" or ""
    st.git_status_str = git_status_str
    st.is_ignore_dir = is_ignore_dir
    st.is_untracked_dir = is_untracked_dir
    ui.render()
end)

local clear_state = ya.sync(function(st)
    st.git_branch = ""
    st.git_file_status = ""
    st.git_is_dirty = ""
    ui.render()
end)

local function update_git_status(path)
    ya.emit("plugin", {"git"})
end

local is_in_git_dir = ya.sync(function(st)
    return (st.git_branch ~= nil and st.git_branch ~= "") and cx.active.current.cwd or nil
end)

local flush_empty_folder_status = ya.sync(function(st)
    local cwd = cx.active.current.cwd
    local folder = cx.active.current
    if #folder.window == 0 then
        clear_state()
        ya.emit("plugin", {"git", ya.quote(tostring(cwd))})
    end
end)

local set_opts_default = ya.sync(function(state, opts)
    if (opts ~= nil and opts.show_brach ~= nil) then
        state.opt_show_brach = opts.show_brach
    else
        state.opt_show_brach = true
    end
end)

local M = {
    setup = function(st, opts)
        set_opts_default(st, opts)

        local function linemode_git(self)
            local f = self._file
            local git_span = ui.Line {}
            local git_status
            if st.git_branch ~= nil and st.git_branch ~= "" then
                local name = f.name:gsub("\r", "?", 1)
                if st.is_ignore_dir then
                    git_status = "."
                elseif st.is_untracked_dir then
                    git_status = "?"
                elseif st.git_file_status and st.git_file_status[name] then
                    git_status = st.git_file_status[name]
                else
                    git_status = nil
                end

                local color = set_status_color(git_status)
                if f.is_hovered then
                    git_span = (git_status) and ui.Span(git_status .. " ") or ui.Span("✓ ")
                else
                    git_span = (git_status) and ui.Span(git_status .. " "):fg(color) or ui.Span("✓ "):fg(color)
                end
            end
            return git_span
        end
        Linemode:children_add(linemode_git, 8000)

        local function cwd_change_detect(self)
            local cwd = cx.active.current.cwd
            if st.cwd ~= cwd then
                st.cwd = cwd
                clear_state()
                ya.emit("plugin", {"git"})
            end
            return ui.Line {}
        end
        Header:children_add(cwd_change_detect, 8000, Header.LEFT)

        local function header_git(self)
            return (st.git_branch and st.git_branch ~= "") and
                       ui.Line {ui.Span(" <" .. st.git_branch .. st.git_is_dirty .. ">"):fg("#f6a6da")} or ui.Line {}
        end
        if st.opt_show_brach then
            Header:children_add(header_git, 1400, Header.LEFT)
        end

        ps.sub("delete", flush_empty_folder_status)
        ps.sub("trash", flush_empty_folder_status)
    end,

    entry = function(_, _)
        set_opts_default()

        local output
        local git_is_dirty
        local is_ignore_dir, is_untracked_dir
        local git_branch
        local result, _ = Command("git"):arg({"symbolic-ref", "HEAD"}):stdout(Command.PIPED):output()

        output = result.stdout
        if output ~= nil and output ~= "" then
            local split_output = string_split(output:sub(1, -2), "refs/heads/")
            git_branch = split_output[2]
        elseif is_in_git_dir() then
            git_branch = nil
        else
            return
        end

        local git_status_str = ""
        local git_file_status = nil
        local result, _ = Command("git"):arg({"--no-optional-locks", "-c", "core.quotePath=", "status", "--ignored",
                                              "-s", "--ignore-submodules=dirty"}):stdout(Command.PIPED):output()

        output = result.stdout
        if output ~= nil and output ~= "" then
            git_status_str = output
            git_file_status, git_is_dirty, is_ignore_dir, is_untracked_dir = make_git_table(git_status_str)
        end
        save(git_branch, git_file_status, git_is_dirty, git_status_str, is_ignore_dir, is_untracked_dir)
    end
}

function M:fetch()
    local path = is_in_git_dir()
    if path then
        update_git_status(path)
    end
    return false
end

return M
