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
    auto_exit_when_unmatch = false,
    enable_capital_lable = true,
	search_patterns = ({"%d+.1080p","第%d+集","%.E%d+","S%d+E%d+",})
})

require("status-owner"):setup({
	color = "#d98a8a"
})

require("status-mtime"):setup({
	color = "#ba884a"
})

require("header-hidden"):setup({
    color = "#88c2f4"
})

require("header-host"):setup({
    color = "#8bca4b"
})


require("cd-last"):setup()


require("git"):setup()
require("current-size"):setup({
    folder_size_ignore = {"/home/wrq","/","/home"},
})

require("full-border"):setup()

require("mime-preview"):setup()

require("autofilter"):setup()
-- require("session"):setup({
-- 	sync_yanked = true,
-- })

require("mime-ext"):setup {
	-- Expand the existing filename database (lowercase), for example:
	-- with_files = {
	-- 	makefile = "text/makefile",
	-- 	-- ...
	-- },

	-- Expand the existing extension database (lowercase), for example:
	with_exts = require("mime-preview"):get_mime_data(),

	-- If the mime-type is not in both filename and extension databases,
	-- then fallback to Yazi's preset `mime` plugin, which uses `file(1)`
	fallback_file1 = true,
}
