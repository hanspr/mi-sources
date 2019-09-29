
VERSION="1.0.0"

local writesettings = false

if GetPluginOption("css","version") == nil then
	AddPluginOption("css","version", VERSION)
	writesettings = true
elseif GetPluginOption("css","version") ~= VERSION then
	SetPluginOption("css","version", VERSION)
	writesettings = true
end

if writesettings then
	WritePluginSettings("css")
end

AddRuntimeFile("css", "help", "help/css-plugin.md")

function compress(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/mi-ide/plugins/css/compress.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
    CurView():Center(false)
end

function decompress(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/mi-ide/plugins/css/decompress.pl '" .. CurView().Buf.Path .. "'")
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

