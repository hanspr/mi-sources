
VERSION = "1.0.10"

local curLoc = {}
local writesettings = false
local home = os.getenv("HOME")

curLoc.X = 0
curLoc.Y = -1

if GetPluginOption("perl", "perlsyntaxstrict") == nil then
    AddPluginOption("perl", "perlsyntaxstrict", false)
    writesettings = true
end

if GetPluginOption("perl", "perlsyntax") == nil then
    AddPluginOption("perl", "perlsyntax", true)
    writesettings = true
end

if GetPluginOption("perl", "perltidy") == nil then
    AddPluginOption("perl", "perltidy", false)
    writesettings = true
elseif GetPluginOption("perl", "perltidy") == true then
    local msg, err = ExecCommand("which", "perltidy")
    if err ~= nil then
        SetPluginOption("perl", "perltidy", false)
        writesettings = true
    else
        local f = io.open(home .. "/.perltidyrc", "r")
        if f == nil then
            SetPluginOption("perl", "perltidy", false)
            writesettings = true
        else
            io.close(f)
        end
    end
end

if GetPluginOption("perl", "version") == nil then
    AddPluginOption("perl", "version", VERSION)
    writesettings = true
elseif GetPluginOption("perl", "version") ~= VERSION then
    SetPluginOption("perl", "version", VERSION)
    writesettings = true
end


if writesettings then
    WritePluginSettings("perl")
end

AddRuntimeFile("perl", "help", "help/perl-plugin.md")

function eol()
    CurView().Cursor:End()
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

function togglestrict()
    if GetPluginOption("perl", "perlsyntaxstrict") == true then
        messenger:Message("perl Dirty")
        SetPluginOption("perl", "perlsyntaxstrict", false)
    else
        messenger:Message("perl Strict")
        SetPluginOption("perl", "perlsyntaxstrict", true)
    end
    WritePluginSettings("perl")
end

function toggletidy()
    if GetPluginOption("perl", "perltidy") == true then
        messenger:Message("perl tidy off")
        SetPluginOption("perl", "perltidy", false)
    else
        if GetOption("useformatter") == false then
            messenger:Message("Formatter disabled by local option 'useformatter'")
            return
        end
        local msg, err = ExecCommand("which", "perltidy")
        if err == nil then
            local f = io.open(home .. "/.perltidyrc", "r")
            if f == nil then
                messenger:Warning("Configure .perltidyrc to use this funtionality")
            else
                io.close(f)
                SetPluginOption("perl", "perltidy", true)
                messenger:Message("perl tidy on")
            end
        else
            messenger:Message("Install perltidy")
        end
    end
    WritePluginSettings("perl")
end

function perlsyntaxoff()
    if GetPluginOption("perl", "perlsyntax") == true then
        messenger:Message("perl syntax off")
        SetPluginOption("perl", "perlsyntax", false)
    else
        messenger:Message("perl syntax on")
        SetPluginOption("perl", "perlsyntax", true)
    end
    WritePluginSettings("perl")
end

function perlCheck(view, fpath)
    local ps = 0
    local pcheck
    local scheck
    local msgp
    local msg

    if GetPluginOption("perl", "perlsyntax") == false then
        return true
    end
    if GetPluginOption("perl", "perlsyntaxstrict") == true then
        msgp, err = ExecCommand("perl", "-c", "-Mstrict", fpath)
        pcheck = "Strict"
    else
        msgp, err = ExecCommand("perl", "-cX", fpath)
        pcheck = "Dirty"
    end
    if string.find(msgp, "syntax OK") == nil then
        scheck = "error"
    else
        if GetPluginOption("perl", "perlsyntaxstrict") == true and string.find(msgp, "WARN") ~= nil then
            messenger:AddLog(msgp)
        end
        scheck = "ok"
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
        if string.find(msgp, "EOF") == nil then
            for ch in string.gmatch(msgp, "line (%d+)") do
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
    if GetPluginOption("perl", "perltidy") == true and GetOption("useformatter") == true then
        msg, err = ExecCommand("perltidy", "-q", "-b", fpath)
        if err == nil then
            msg, err = ExecCommand("rm", "-f", fpath .. ".bak")
        else
            messenger:Error("Error perltidy")
        end
        CurView():ReOpen()
    end
    messenger:Success(msgp .. " (" .. pcheck .. ")")
    return true
end

function onSave(view)
    local fpath = CurView().Buf.Path

    return perlCheck(view, fpath)
end

function onDisplayFocus(view)
    BindKey("F9", "perl.toggletidy")
    BindKey("F10", "perl.perlsyntaxoff")
    BindKey("F11", "perl.togglestrict")
    BindKey("AltEnter", "perl.addcomma")
end

function onDisplayBlur(view)
    BindKey("F9", "Unbindkey")
    BindKey("F10", "Unbindkey")
    BindKey("F11", "Unbindkey")
    BindKey("AltEnter", "Unbindkey")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

-- Insert ; at the end of lines to avoid typing it
-- Use Alt Enter to avoid going to the end after for the new line

function onBackspace(view)
    if view.Buf:Line(view.Cursor.Loc.Y) == ";" then
        view:Delete(false)
    end
end


