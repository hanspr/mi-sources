
VERSION = "1.0.5"

local curLoc = {}
local writesettings = false
local home = os.getenv("HOME")

curLoc.X = 0
curLoc.Y = -1

if GetPluginOption("html", "htmltidy") == nil then
    AddPluginOption("html", "htmltidy", false)
    writesettings = true
elseif GetPluginOption("html", "htmltidy") == true then
    local msg, err = ExecCommand("which", "tidy")
    if err ~= nil then
        SetPluginOption("html", "htmltidy", false)
        writesettings = true
    else
        local f = io.open(home .. "/.tidyrc", "r")
        if f == nil then
            SetPluginOption("html", "htmltidy", false)
            writesettings = true
        else
            io.close(f)
        end
    end
end

if GetPluginOption("html", "version") == nil then
    AddPluginOption("html", "version", VERSION)
    writesettings = true
elseif GetPluginOption("html", "version") ~= VERSION then
    SetPluginOption("html", "version", VERSION)
    writesettings = true
end

if writesettings then
    WritePluginSettings("html")
end

--AddRuntimeFile("html", "help", "help/html-plugin.md")

function toggletidy()
    if GetPluginOption("html", "htmltidy") == true then
        messenger:Message("html tidy off")
        SetPluginOption("html", "htmltidy", false)
    else
        local msg, err = ExecCommand("which", "tidy")
        if err == nil then
            local f = io.open(home .. "/.tidyrc", "r")
            if f == nil then
                messenger:Warning("Configure .tidyrc to use this funtionality")
            else
                io.close(f)
                SetPluginOption("html", "htmltidy", true)
                messenger:Message("html tidy on")
            end
        else
            messenger:Message("Install tidy")
        end
    end
    WritePluginSettings("html")
end

function htmlCheck(view, fpath)
    local ps = 0
    local pcheck
    local scheck
    local msgp
    local msg

    if GetPluginOption("html", "htmltidy") == false then
        return true
    end
    msgp, err = ExecCommand("tidy", fpath)
    messenger:AddLog(msgp)
    if err ~= nil and (string.find(msgp, "Warning:") ~= nil or string.find(msgp, "Error:") ~= nil) then
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
        local xy={}
        xy.X = 0
        xy.Y = -99
        if string.find(msgp, "EOF") == nil then
            for ch in string.gmatch(msgp, "line (%d+) ") do
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
        CurView():ReOpen()
    end
    messenger:Success(msgp)
    return true
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return htmlCheck(view, fpath)
end

function onDisplayFocus(view)
    BindKey("F9", "html.toggletidy")
end

function onViewOpen(view)
    BindKey("F9", "html.toggletidy")
end

