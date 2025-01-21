
VERSION = "1.0.3"

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

function compress(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/mi-ide/plugins/xslt/compress.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
    CurView():Center(false)
end

function decompress(view)
    CurView():Save(false)
    local handle = io.popen("perl ~/.config/mi-ide/plugins/xslt/decompress.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()

    CurView():ReOpen()
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

    if GetPluginOption("xslt", "checksyntax") == false then
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
    messenger:Success("Syntax ok")
    return true
end

function onDisplayFocus(view)
    BindKey("F10", "xslt.xsltsyntaxoff")
    MakeCommand("xsltcompress", "xslt.compress", 0)
    BindKey("F11", "xslt.compress")
    MakeCommand("xsltdecompress", "xslt.decompress", 0)
    BindKey("F12", "xslt.decompress")
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return xsltCheck(view, fpath)
end

function onOpen(view)
    onDisplayFocus(view)
end
