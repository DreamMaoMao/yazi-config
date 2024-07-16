local function setup(state,config)
	local user_color = config.user_color and config.user_color or "#D4BB91"


    local function status_owner(self)
    	local h = cx.active.current.hovered
    	if h == nil or ya.target_family() ~= "unix" then
    		return ui.Line {}
    	end

    	return ui.Line {
    		ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg(user_color),
    		ui.Span(":"),
    		ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg(user_color),
    		ui.Span(" "),
    	}
    end

	Status:children_add(status_owner,500,Status.RIGHT)
end

return { setup = setup }