local function setup(state,config)
	local border_color = config.border_color and config.border_color or "#9a8774"
	local user_color = config.user_color and config.user_color or "#D4BB91"

    function Manager:render(area)

    	local chunks = self:layout(area)

    	local bar = function(c, x, y)
    		x, y = math.max(0, x), math.max(0, y)
    		return ui.Bar(ui.Rect { x = x, y = y, w = ya.clamp(0, area.w - x, 1), h = math.min(1, area.h) }, ui.Bar.TOP):symbol(c):style(ui.Style():fg(border_color))
    	end

    	return ya.flat {
    		-- Borders
    		ui.Border(area, ui.Border.ALL):type(ui.Border.ROUNDED):style(ui.Style():fg(border_color)),
    		ui.Bar(chunks[1], ui.Bar.RIGHT):style(ui.Style():fg(border_color)),
    		ui.Bar(chunks[3], ui.Bar.LEFT):style(ui.Style():fg(border_color)),

    		bar("┬", chunks[1].right - 1, chunks[1].y),
    		bar("┴", chunks[1].right - 1, chunks[1].bottom - 1),
    		bar("┬", chunks[2].right, chunks[2].y),
    		bar("┴", chunks[2].right, chunks[1].bottom - 1),

    		-- Parent
    		Parent:render(chunks[1]:padding(ui.Padding.xy(1))),
    		-- Current
    		Current:render(chunks[2]:padding(ui.Padding.y(1))),
    		-- Preview
    		Preview:render(chunks[3]:padding(ui.Padding.xy(1))),
    	}
    end

    function Status:owner()
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

    function Status:render(area)
    	self.area = area

    	local left = ui.Line { self:mode(), self:size(), self:name() }
    	local right = ui.Line { self:owner(), self:permissions(), self:percentage(), self:position() }
    	return {
    		ui.Paragraph(area, { left }),
    		ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
    		table.unpack(Progress:render(area, right:width())),
    	}
    end
end

return { setup = setup }