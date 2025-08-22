
VERSION = "1.0.12"

local curLoc = {}
local writesettings = false
local options = ""

curLoc.X = 0
curLoc.Y = -1

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

if GetPluginOption("go", "govet") == nil then
    AddPluginOption("go", "govet", true)
    writesettings = true
end

if GetPluginOption("go", "golint") == nil then
    AddPluginOption("go", "golint", true)
    writesettings = true
end

if writesettings then
    WritePluginSettings("go")
end

AddRuntimeFile("go", "help", "help/go-plugin.md")

function vet(view)
    local ps = 0
    msg, err = ExecCommand("go", "vet")
    if err ~= nil then
        HandleError(view, msg)
        messenger:Error("go vet Error")
        return false
    else
        HandleSuccess(view)
        messenger:Success("go vet success")
        return true
    end
end

function lint(view)
    local ps = 0
    msg, err = ExecCommand("golint", view.Buf.Path)
    if err ~= nil or msg ~= "" then
        HandleError(view, msg)
        messenger:Error("golint Error")
        return false
    else
        HandleSuccess(view)
        messenger:Success("golint success")
        return true
    end
end

function gofmt(view)
    local ps = 0

    msg, err = ExecCommand("gofmt", "-e", CurView().Buf.Path)
    if err ~= nil then
        HandleError(view, msg)
        messenger:Error("Syntax Error")
        return false
    else
        HandleSuccess(view)
        messenger:Success("Syntax OK")
        return true
    end
end

function HandleError(view, msg)
    local pos = 0;

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
    for ch in string.gmatch(msg, ":(%d+):") do
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
end

function HandleSuccess(view)
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
end

function onSave(view)
    if GetPluginOption("go", "goimports") then
        goimports()
    end
    if GetPluginOption("go", "gofmt") then
        local result = gofmt(view)
        if result == false then
            return false
        end
    end
    if GetPluginOption("go", "golint") then
        local result = lint(view)
        if result == false then
            return false
        end
    end
    if GetPluginOption("go", "govet") then
        return vet(view)
    end
    return true
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

function togglegoimports()
    if GetPluginOption("go", "goimports") == true then
        messenger:Message("goimports off")
        SetPluginOption("go", "goimports", false)
    else
        messenger:Message("goimports on")
        SetPluginOption("go", "goimports", true)
    end
    WritePluginSettings("go")
end

function togglegofmt()
    if GetPluginOption("go", "gofmt") == true then
        messenger:Message("gofmt off")
        SetPluginOption("go", "gofmt", false)
    else
        messenger:Message("gofmt on")
        SetPluginOption("go", "gofmt", true)
    end
    WritePluginSettings("go")
end

function togglegovet()
    if GetPluginOption("go", "govet") == true then
        messenger:Message("govet off")
        SetPluginOption("go", "govet", false)
    else
        messenger:Message("govet on")
        SetPluginOption("go", "govet", true)
    end
    WritePluginSettings("go")
end

function togglegolint()
    if GetPluginOption("go", "golint") == true then
        messenger:Message("golint off")
        SetPluginOption("go", "golint", false)
    else
        messenger:Message("golint on")
        SetPluginOption("go", "golint", true)
    end
    WritePluginSettings("go")
end

function onDisplayFocus(view)
    BindKey("F9", "go.togglegofmt")
    BindKey("F10", "go.togglegovet")
    BindKey("F11", "go.togglegolint")
    BindKey("F12", "go.togglegoimports")
end

function onDisplayBlur(view)
    BindKey("F9", "Unbindkey")
    BindKey("F10", "Unbindkey")
    BindKey("F11", "Unbindkey")
    BindKey("F12", "Unbindkey")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

