
VERSION = "1.0.3"

local indent = -1
local home = os.getenv("HOME")
local curLoc = {}

curLoc.X = 0
curLoc.Y = -1

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

function Check(view, fpath)
    local ps = 0
    msg, err = ExecCommand("python3", "-m", "py_compile", fpath)
    if err ~= nil then
        if view:GetHelperView() == nil then
            curLoc.X = view.Cursor.Loc.X
            curLoc.Y = view.Cursor.Loc.Y
            ps = 1
        end
        view:OpenHelperView("h", "", msg)
        if ps == 1 then
            view:PreviousSplit(false)
        end
        local xy = {}
        xy.X = 0
        xy.Y = -99
        if string.find(msg, "EOF") == nil then
            for ch in string.gmatch(msg, "line (%d+)") do
                xy.Y = tonumber(ch)-1;
                break
            end
        end
        if xy.Y ~= -99  then
            if xy.Y < 0 then
                xy.Y = 0
            end
            view.Cursor:GotoLoc(xy)
            view:Center(false)
            view:Relocate()
        end
        messenger:Error("Syntax Error")
        return false
    else
        if view:GetHelperView() ~= nil then
            view:CloseHelperView()
        end
        if curLoc.Y ~= -1 then
            view:SetLastView()
            view.Cursor:GotoLoc(curLoc)
            view:Center(false)
            view:Relocate()
        end
        curLoc.Y = -1
    end
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return Check(view, fpath)
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

