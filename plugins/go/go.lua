
VERSION = "1.0.3"

local curLoc = {}
local writesettings = false

if GetPluginOption("go", "version") == nil then
    AddPluginOption("go", "version", VERSION)
    writesettings = true
elseif GetPluginOption("go", "version") ~= VERSION then
    SetPluginOption("go", "version", VERSION)
    writesettings = true
end

if GetPluginOption("go", "goimports") == nil then
    AddPluginOption("go", "goimports", false)
    writesettings = true
end

if GetPluginOption("go", "gofmt") == nil then
    AddPluginOption("go", "gofmt", true)
    writesettings = true
end

if writesettings then
    WritePluginSettings("go")
end

--MakeCommand("goimports", "go.goimports", 0)
--MakeCommand("gofmt", "go.gofmt", 0)
AddRuntimeFile("go", "help", "help/go-plugin.md")

function onSave(view)
    if GetPluginOption("go", "goimports") then
        goimports()
    end
    if GetPluginOption("go", "gofmt") then
        return gofmt(view)
    end
end

function gofmt(view)
    local ps = 0

    msg, err = ExecCommand("gofmt", "-e", CurView().Buf.Path)
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
        local xy={}
        xy.X = 0
        xy.Y = -99
        for ch in string.gmatch(msg, "(%d+):") do
            xy.Y = tonumber(ch)-1;
            break
        end
        if xy.Y ~= -99  then
            if xy.Y < 0 then
                xy.Y = 0
            end
            view.Cursor:GotoLoc(xy)
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
        CurView():Save(false)
        local handle = io.popen("gofmt -w " .. CurView().Buf.Path)
        local result = handle:read("*a")
        handle:close()
        CurView():ReOpen()
        messenger:Success("Syntax OK")
        return true
    end
end

function goimports()
    CurView():Save(false)
    local handle = io.popen("goimports -w " .. CurView().Buf.Path)
    local result = split(handle:read("*a"), ":")
    handle:close()

    CurView():ReOpen()
end

function split(str, sep)
    local result = {}
    local regex = ("([^%s]+)"):format(sep)
    for each in str:gmatch(regex) do
        table.insert(result, each)
    end
    return result
end


