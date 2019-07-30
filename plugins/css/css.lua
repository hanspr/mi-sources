
VERSION="0.0.1"

function flatten(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/micro-ide/plugins/css/flatten.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
end

function unflatten(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/micro-ide/plugins/css/unflatten.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
end

function onDisplayFocus(view)
	MakeCommand("cssflatten","css.flatten",0)
	BindKey("F12", "css.flatten")
	MakeCommand("cssunflatten","css.unflatten",0)
	BindKey("F11", "css.unflatten")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

function onOpen(view)
    onDisplayFocus(view)
end
