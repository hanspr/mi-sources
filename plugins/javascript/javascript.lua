
VERSION = "1.0.5"

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

    if GetPluginOption("javascript", "jssyntax") == false then
        return true
    end
    msgp, err = ExecCommand("node", "--check", fpath)
    if err ~= nil or string.find(msgp, "SyntaxError") ~= nil then
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
        for ch in string.gmatch(msgp, ":(%d+)") do
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
        messenger:Error("Syntax Error")
        return false
    else
        if GetPluginOption("javascript", "jstidy") == true then
            if tidytool == "js-beautify" then
                msgp, err = ExecCommand("js-beautify", "-r", fpath)
            elseif tidytool == "uglifyjs" then
                msgp, err = ExecCommand("uglifyjs", fpath, "-b", "-o", fpath .. ".new")
                msgp, err = ExecCommand("mv", "-f", fpath .. ".new", fpath)
            end
        end
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
        CurView():ReOpen()
    end
    messenger:Success("Syntax ok")
    return true
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return jsCheck(view, fpath)
end

function onDisplayFocus(view)
    BindKey("F9", "javascript.toggletidy")
    BindKey("F10", "javascript.jssyntaxoff")
    BindKey("F11", "javascript.compress")
end

function onViewOpen(view)
    onDisplayFocus(view)
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

--AddRuntimeFile("javascript", "help", "help/js-plugin.md")
