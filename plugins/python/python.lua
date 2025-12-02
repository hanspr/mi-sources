
VERSION = "1.0.2"

local indent = -1
local home = os.getenv("HOME")

if GetPluginOption("python", "version") == nil then
    AddPluginOption("python", "version", VERSION)
    writesettings = true
elseif GetPluginOption("python", "version") ~= VERSION then
    SetPluginOption("python", "version", VERSION)
    writesettings = true
end

if writesettings then
    WritePluginSettings("python")
end

function preInsertNewline(view)
    indent = -1
    view = CurView()
    xy = {}
    xy.X = view.Cursor.Loc.X
    xy.Y = view.Cursor.Loc.Y
    line = view.Buf:Line(xy.Y)
    l = utf8len(line)
    if xy.X < l then
        return true
    end
    if string.sub(line,-1) == ":" then
        indent = #GetLeadingWhitespace(line)
    end
end

function onInsertNewline(view)
    if indent < 0 then
        return true
    end
    xy = {}
    xy.X = view.Cursor.Loc.X
    xy.Y = view.Cursor.Loc.Y
    line = view.Buf:Line(xy.Y)
    line_indent = #GetLeadingWhitespace(line)
    if line_indent <= indent then
        view:InsertTab(false)
    end
    return true
end

