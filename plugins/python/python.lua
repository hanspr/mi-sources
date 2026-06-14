
VERSION = "1.0.6"

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

if GetPluginOption("python", "typehints") == nil then
    AddPluginOption("python", "typehints", false)
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

function typehintsoff()
    if GetPluginOption("python", "typehints") == true then
        messenger:Message("python type hints off")
        SetPluginOption("python", "typehints", false)
    else
        msg, err = ExecCommand("which", "ty")
        if err == nil then
            messenger:Message("python type hints on")
            SetPluginOption("python", "typehints", true)
        else
            messenger:Warning("ty is missing")
        end
    end
    WritePluginSettings("python")
end

function settool()
    msg, err = ExecCommand("which", "mypy")
    if err == nil then
        tool = "mypy"
    end
    msg, err = ExecCommand("which", "pylint")
    if err == nil then
        tool = "pylint"
    end
    msg, err = ExecCommand("which", "ruff")
    if err == nil then
        tool = "ruff"
    end
    messenger:Message("lint tool:", tool)
end

function Check(view, fpath)
    local ps = 0
    local msg, err, strerr
    if GetPluginOption("python", "checksyntax") == false then
        return true
    end
    if tool == "py_compile" then
        strerr = "line (%d+)"
        msg, err = ExecCommand("python3", "-m", "py_compile", fpath)
    elseif tool == "ruff" then
        strerr = ":(%d+):"
        msg, err = ExecCommand("ruff", "check", fpath)
    else
        strerr = ":(%d+):"
        if tool == "pylint" then
            msg, err = ExecCommand(tool, "--disable=all", "--enable=E,unused-variable", fpath)
        else
            msg, err = ExecCommand(tool, fpath)
        end
    end
    if err ~= nil then
        return HandleError(view, msg, strerr, "Syntax Error")
    end
    return HandleSuccess(view, tool .. " : syntax check ok")
end

function TypeHints(view, fpath)
    local ps = 0
    local msg, err, strerr
    if GetPluginOption("python", "typehints") == false then
        return true
    end
    strerr = ":(%d+):"
    msg, err = ExecCommand("ty", "check", fpath)
    if err ~= nil then
        return HandleError(view, msg, strerr, "types check Error")
    end
    return HandleSuccess(view, "type check ok")
end

function HandleError(view, msg, strerr, errmsg)
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
    messenger:Error(errmsg)
    return false
end

function HandleSuccess(view, msg)
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
    messenger:Success(msg)
    return true
end

function onSave(view)
    local fpath = CurView().Buf.Path
    local err = true

    err = Check(view, fpath)
    if err == false then
        return false
    end
    return TypeHints(view, fpath)
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
    BindKey("F11", "python.typehintsoff")
end

function onDisplayBlur(view)
    BindKey("F10", "Unbindkey")
    BindKey("F11", "typehintsoff")
end

function onViewOpen(view)
    onDisplayFocus(view)
    settool()
end
