-- require("keyjump"):setup({
-- 	icon_fg = "#fda1a1",
-- })

require("easyjump"):setup({
	icon_fg = "#fda1a1",
    first_key_fg = "#df6249"
})

require("searchjump"):setup({
	unmatch_fg = "#b2a496",
    match_str_fg = "#000000",
    match_str_bg = "#73AC3A",
    first_match_str_fg = "#000000",
    first_match_str_bg = "#73AC3A",
    lable_fg = "#EADFC8",
    lable_bg = "#BA603D",
    only_current = false,
    show_search_in_statusbar = false,
    auto_exit_when_unmatch = true,
    enable_capital_lable = true,
	search_patterns = ({"%d+.1080p","第%d+集","%.E%d+","S%d+E%d+",})
})

require("custom"):setup({
	border_color = "#9a8774",
	user_color = "#D4BB91"
})

require("git-status"):setup({
    style = "linemode" -- beside or linemode
})

require("current-size"):setup({
    folder_size_ignore = ({"/home/wrq","/","/home"}),
})

-- require("zoxide"):setup({
-- 	update_db = true,
-- })

