
VERSION="0.0.1"

function compress(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/micro-ide/plugins/css/compress.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
end

function decompress(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/micro-ide/plugins/css/decompress.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
end

function onDisplayFocus(view)
	MakeCommand("csscompress","css.compress",0)
	BindKey("F12", "css.compress")
	MakeCommand("cssdecompress","css.decompress",0)
	BindKey("F11", "css.decompress")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

function onOpen(view)
    onDisplayFocus(view)
end
