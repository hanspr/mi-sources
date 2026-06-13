
VERSION = "1.0.4"

local indent = -1
local home = os.getenv("HOME")
local curLoc = {}
local tool = "py_compile"
curLoc.X = 0
curLoc.Y = -1

if GetPluginOption("python", "version") == nil then
    AddPluginOption("python", "version", VERSION)
    writesettings = true
elseif GetPluginOption("python", "version") ~= VERSION then
    SetPluginOption("python", "version", VERSION)
    writesettings = true
end

if GetPluginOption("python", "checksyntax") == nil then
    AddPluginOption("python", "checksyntax", true)
    writesettings = true
end

if writesettings then
    WritePluginSettings("python")
end

function syntaxoff()
    if GetPluginOption("python", "checksyntax") == true then
        messenger:Message("python syntax off")
        SetPluginOption("python", "checksyntax", false)
    else
        messenger:Message("python syntax on, tool", tool)
        SetPluginOption("python", "checksyntax", true)
    end
    WritePluginSettings("python")
end

function settool()
    msg, err = ExecCommand("which", "pylint")
    if err == nil then
        tool = "pylint"
    end
    msg, err = ExecCommand("which", "mypy")
    if err == nil then
        tool = "mypy"
    end
    messenger:Message("lint tool:", tool)
end

function Check(view, fpath)
    local ps = 0
    local msg, err, strerr
    if GetPluginOption("python", "checksyntax") == false then
        messenger:Message("Syntax off")
        return true
    end
    if tool == "py_compile" then
        strerr = "line (%d+)"
        msg, err = ExecCommand("python3", "-m", "py_compile", fpath)
    else
        strerr = ":(%d+):"
        if tool == "pylint" then
            msg, err = ExecCommand(tool, "--disable=C,R", fpath)
        else
            msg, err = ExecCommand(tool, fpath)
        end
    end
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
            for ch in string.gmatch(msg, strerr) do
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
    messenger:Success(tool, " : syntax check ok")
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

function onDisplayFocus(view)
    BindKey("F10", "python.syntaxoff")
end

function onDisplayBlur(view)
    BindKey("F10", "Unbindkey")
end

function onViewOpen(view)
    onDisplayFocus(view)
    settool()
end
