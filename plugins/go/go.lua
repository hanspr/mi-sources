
VERSION = "1.0.6"

local curLoc = {}
local writesettings = false
local lastgobuild = ""
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

if writesettings then
    WritePluginSettings("go")
end

MakeCommand("gobuild", "go.build", 1)
AddRuntimeFile("go", "help", "help/go-plugin.md")

function build(...)
    local ps = 0
    view = CurView()
    if input == "off" then
        lastgobuild = ""
        return true
    end
    lastgobuild = arg[arg["n"]]
    msg, err = ExecCommand("go", "build", unpack(arg))
    if err ~= nil then
        HandleError(view, msg)
        messenger:Error("Compile Error")
        return false
    else
        HandleSuccess(view)
        messenger:Success("Compile success")
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
        if lastgobuild ~= "" then
            return build(lastgobuild)
        end
        return result
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

function onDisplayFocus(view)
    BindKey("F10", "go.togglegoimports")
    BindKey("F11", "go.togglegofmt")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

