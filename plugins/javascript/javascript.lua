
VERSION = "1.0.12"

local curLoc = {}
local writesettings = false
local home = os.getenv("HOME")
local tidytool = ""

curLoc.X = 0
curLoc.Y = -1

function setTidyTool()
    local msg, err = ExecCommand("which", "js-beautify")
    if err == nil then
        return "js-beautify"
    else
        local msg, err = ExecCommand("which", "uglifyjs")
        if err == nil then
            return "uglifyjs"
        end
    end
    return ""
end

function compress(view)
    local fpath = CurView().Buf.Path
    local fpnew = fpath:gsub(".js", ".min.js")

    CurView():Save(false)
    local msg, err = ExecCommand("uglifyjs", fpath, "-o", fpnew)
    if err == nil then
        messenger:Success("File saved as : ", fpnew)
    else
        messenger:Error("Please install uglifyjs")
    end
end

function togglestrict()
    if GetPluginOption("javascript", "strict") == true then
        messenger:Message("syntax Dirty")
        SetPluginOption("javascript", "strict", false)
    else
        messenger:Message("syntax Strict")
        SetPluginOption("javascript", "strict", true)
    end
    WritePluginSettings("javascript")
end

function toggletidy()
    if GetPluginOption("javascript", "jstidy") == true then
        messenger:Message("js tidy off")
        SetPluginOption("javascript", "jstidy", false)
    else
        tidytool = setTidyTool()
        if tidytool == "" then
            messenger:Message("Install js-beautify or uglifyjs")
        else
            SetPluginOption("javascript", "jstidy", true)
            messenger:Message("js tidy on")
        end
    end
    WritePluginSettings("javascript")
end

function jssyntaxoff()
    if GetPluginOption("javascript", "jssyntax") == true then
        messenger:Message("javascript syntax off")
        SetPluginOption("javascript", "jssyntax", false)
    else
        local msg, err = ExecCommand("which", "node")
        if err ~= nil then
            messenger:Message("Install node to use this syntax check")
        else
            messenger:Message("javascript syntax on")
            SetPluginOption("javascript", "jssyntax", true)
        end
    end
    WritePluginSettings("javascript")
end

function jsCheck(view, fpath)
    local ps = 0
    local pcheck
    local scheck
    local msgp
    local msg
    local err
    local pcheck = "Dirty"
    local find = ":(%d+):"

    if GetPluginOption("javascript", "jssyntax") == false then
        jstidy(view, fpath)
        return true
    end
    if GetPluginOption("javascript", "strict") == true then
        msgp, err = ExecCommand("npx", "eslint", fpath)
        pcheck = "Strict"
        find = "%s*(%d+):"
        for ch in string.gmatch(msgp, "Oops") do
            messenger:Error("configure eslint correctly before use")
            return false
        end
        for ch in string.gmatch(msgp, "ESLint:") do
            messenger:Error("configure eslint correctly before use")
            return false
        end
    else
        msgp, err = ExecCommand("node", "--check", fpath)
    end
    if err ~= nil or string.find(msgp, "Error: ") ~= nil then
        scheck = "error"
    else
        scheck = "ok"
        msgp = ""
    end
    if scheck ~= "ok" then
        if view:GetHelperView() == nil then
            curLoc.X = view.Cursor.Loc.X
            curLoc.Y = view.Cursor.Loc.Y
            ps = 1
        end
        view:OpenHelperView("h", "", msgp)
        if ps == 1 then
            view:PreviousSplit(false)
        end
        local xy = {}
        xy.X = 0
        xy.Y = -99
        messenger:AddLog(find)
        messenger:AddLog(msgp)
        for ch in string.gmatch(msgp, find) do
            messenger:AddLog(ch)
            xy.Y = tonumber(ch)-1;
            break
        end
        if xy.Y ~= -99  then
            if xy.Y < 0 then
                xy.Y = 0
            end
            view.Cursor:GotoLoc(xy)
            view:Center(false)
            view:Relocate()
        end
        messenger:Error("Syntax Error ", pcheck)
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
        jstidy(view, fpath)
    end
    messenger:Success("Syntax ok ", pcheck)
    return true
end

function jstidy(view, fpath)
    if GetPluginOption("javascript", "jstidy") == true then
        if tidytool == "js-beautify" then
            msgp, err = ExecCommand("js-beautify", "-r", "-n", fpath)
        elseif tidytool == "uglifyjs" then
            msgp, err = ExecCommand("uglifyjs", fpath, "-b", "-o", fpath .. ".new")
            msgp, err = ExecCommand("mv", "-f", fpath .. ".new", fpath)
        end
        CurView():ReOpen()
    end
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return jsCheck(view, fpath)
end

function addcomma()
    view = CurView()
    xy = {}
    xy.X = view.Cursor.Loc.X
    xy.Y = view.Cursor.Loc.Y
    line = view.Buf:Line(xy.Y)
    if string.find(line, ";$") then
        return true
    end
    view.Cursor:End()
    xy.X = view.Cursor.Loc.X
    xy.Y = view.Cursor.Loc.Y
    view.Buf:Insert(xy, ";")
end

function onDisplayFocus(view)
    BindKey("F9", "javascript.toggletidy")
    BindKey("F10", "javascript.jssyntaxoff")
    BindKey("F11", "javascript.togglestrict")
    BindKey("F12", "javascript.compress")
    BindKey("AltEnter", "javascript.addcomma")
end

function onDisplayBlur(view)
    BindKey("F9", "Unbindkey")
    BindKey("F10", "Unbindkey")
    BindKey("F11", "Unbindkey")
    BindKey("F12", "Unbindkey")
    BindKey("AltEnter", "Unbindkey")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

if GetPluginOption("javascript", "strict") == nil then
    AddPluginOption("javascript", "strict", false)
    writesettings = true
end

if GetPluginOption("javascript", "jstidy") == nil then
    AddPluginOption("javascript", "jstidy", false)
    writesettings = true
elseif GetPluginOption("javascript", "jstidy") == true then
    tidytool = setTidyTool()
    if tidytool == "" then
        SetPluginOption("javascript", "jstidy", false)
        writesettings = true
    end
end

if GetPluginOption("javascript", "jssyntax") == nil then
    AddPluginOption("javascript", "jssyntax", false)
    writesettings = true
elseif GetPluginOption("javascript", "jssyntax") == true then
    local msg, err = ExecCommand("which", "node")
    if err ~= nil then
        SetPluginOption("javascript", "jssyntax", false)
        writesettings = true
    end
end

if GetPluginOption("javascript", "version") == nil then
    AddPluginOption("javascript", "version", VERSION)
    writesettings = true
elseif GetPluginOption("javascript", "version") ~= VERSION then
    SetPluginOption("javascript", "version", VERSION)
    writesettings = true
end

if writesettings then
    WritePluginSettings("javascript")
end

AddRuntimeFile("javascript", "help", "help/javascript-plugin.md")
