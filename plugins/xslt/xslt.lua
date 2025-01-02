
VERSION = "1.0.0"

local ErrorView = nil
local curLoc = {}
local writesettings = false
local home = os.getenv("HOME")

curLoc.X = 0
curLoc.Y = -1

if GetPluginOption("xslt", "checksyntax") == nil then
    AddPluginOption("xslt", "checksyntax", false)
    writesettings = true
else
    if GetPluginOption("xslt", "checksyntax") == true then
        local msg, err = ExecCommand("which", "xsltproc")
        if err ~= nil then
            SetPluginOption("xslt", "checksyntax", false)
        end
        writesettings = true
    end
end

if GetPluginOption("xslt", "version") == nil then
    AddPluginOption("xslt", "version", VERSION)
    writesettings = true
elseif GetPluginOption("xslt", "version") ~= VERSION then
    SetPluginOption("xslt", "version", VERSION)
    writesettings = true
end

if writesettings then
    WritePluginSettings("xslt")
end

--AddRuntimeFile("xslt", "help", "help/xslt-plugin.md")

function preQuit(view)
    if ErrorView ~= nil  then
        ErrorView:Quit(false)
        ErrorView = nil
        return false
    end
end

function eol()
    CurView().Cursor:End()
end

function xsltsyntaxoff()
    if GetPluginOption("xslt", "checksyntax") == true then
        messenger:Message("xslt syntax off")
        SetPluginOption("xslt", "checksyntax", false)
    else
        local msg, err = ExecCommand("which", "xsltproc")
        if err == nil then
            SetPluginOption("xslt", "checksyntax", true)
            messenger:Message("xslt syntax on")
        else
            messenger:Message("Install xsltproc to test xslt syntax")
        end
    end
    WritePluginSettings("xslt")
end

function xsltCheck(view, fpath)
    local ps = 0
    local pcheck
    local scheck
    local msgp
    local msg

    if GetPluginOption("xslt", "xsltsyntax") == false then
        return true
    end
    msgp, err = ExecCommand("xsltproc", "--noout", fpath)
    if err ~= nil or string.find(msgp, "error") ~= nil then
        scheck = "error"
    else
        scheck = "ok"
    end
    if scheck ~= "ok" then
        --		messenger:Error(msg)
        if ErrorView == nil then
            if curLoc.Y == -1 then
                curLoc.X = view.Cursor.Loc.X
                curLoc.Y = view.Cursor.Loc.Y
            end
            view:HSplitIndex(NewBuffer(msgp, "Error"), 1)
            ErrorView = CurView()
            ErrorView.Type.Kind = 2
            ErrorView.Type.Readonly = true
            ErrorView.Type.Scratch = true
            SetLocalOption("softwrap", "true", ErrorView)
            SetLocalOption("ruler", "false", ErrorView)
            SetLocalOption("autosave", "false", ErrorView)
            SetLocalOption("statusline", "false", ErrorView)
            SetLocalOption("scrollbar", "false", ErrorView)
            ps = 1
        else
            ErrorView.Buf:remove({0, 0}, ErrorView.Buf:End())
            ErrorView.Buf:insert({0, 0}, msgp)
        end
        ErrorView.Cursor:GotoLoc({0, 0})
        if ps == 1 then
            view:PreviousSplit(false)
        end
        local xy={}
        xy.X = 0
        xy.Y = -99
        for ch in string.gmatch(msgp, "xslt:(%d+):") do
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
        if ErrorView ~= nil then
            ErrorView:Quit(false)
            ErrorView = nil
        end
        if curLoc.Y ~= -1 then
            view:SetLastView()
            view.Cursor:GotoLoc(curLoc)
            view:Center(false)
            view:Relocate()
        end
        curLoc.Y = -1
    end
    messenger:Success("Syntax ok")
    return true
end

function onDisplayFocus(view)
    BindKey("F11", "xslt.xsltsyntaxoff")
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return xsltCheck(view, fpath)
end

function onOpen(view)
    onDisplayFocus(view)
end
