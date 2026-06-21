
VERSION = "1.0.25"

local curLoc = {}
local writesettings = false
local options = ""
local lastpkg = ""
local pfile = ""

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
    AddPluginOption("go", "govet", false)
    writesettings = true
end

if GetPluginOption("go", "golint") == nil then
    AddPluginOption("go", "golint", false)
    writesettings = true
end

if writesettings then
    WritePluginSettings("go")
end

AddRuntimeFile("go", "help", "help/go-plugin.md")

function vet(view)
    local ps = 0
    local gomod = false
    local f = io.open("go.mod", "r")
    if f ~= nil then
        io.close(f)
        gomod = true
    end
    if gomod then
        msg, err = ExecCommand("go", "vet")
    else
        msg, err = ExecCommand("go", "vet", view.Buf.Path)
    end
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
    msg, err = ExecCommand("golangci-lint", "run", "--fix", "./")
    if err ~= nil then
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

function modernizefix()
    local ps = 0
    local view = CurView()

    msg, err = ExecCommand("modernize", "--fix", "./...")
    if err ~= nil or msg ~= "" then
        HandleError(view, msg)
        return false
    else
        HandleSuccess(view)
    end
    messenger:Success("modernize done")
    return true
end

function modernize()
    local ps = 0
    local view = CurView()

    msg, err = ExecCommand("modernize", "./...")
    if err ~= nil or msg ~= "" then
        HandleError(view, msg)
        return false
    else
        HandleSuccess(view)
    end
    messenger:Success("modernize done")
    return true
end

function getCorrectPath(ref, path)
    local dirRef, fileRef = ref:match("^(.+)/(.-)$")
    local dirPath, filePath = path:match("^(.+)/(.-)$")
    if path:sub(1, 1) == "/" then
        messenger:AddLog("absolute path")
        return path
    end
    if dirRef:match(dirPath) ~= nil then
        return dirRef .. "/" .. filePath
    end
    return path
end

function HandleError(view, msg)
    local pos = 0;

    if view:GetHelperView() == nil then
        curLoc.X = view.Cursor.Loc.X
        curLoc.Y = view.Cursor.Loc.Y
        ps = 1
    end
    fname = string.find(msg, view.Buf.Fname)
    if fname == nil then
        fname = msg:match("([%w%d_./-]+%.go):")
        if fname ~= nil then
            pfile = view.Buf.AbsPath
            fname = getCorrectPath(pfile, fname)
            messenger:AddLog(fname)
            view:Open(fname)
        end
    end
    view:OpenHelperView("h", "", msg)
    if ps == 1 then
        view:PreviousSplit(false)
    end
    local xy = {}
    xy.X = 0
    xy.Y = -99
    local ms = string.gsub(view.Buf.Fname, "%.", "%.")
    ms = string.gsub(ms, "%-", "%-")
    ms = ms .. ":(%d+):"
    for ch in string.gmatch(msg, ms) do
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
        if pfile ~= "" then
            view:Open(pfile)
            pfile = ""
        end
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
    if GetPluginOption("go", "govet") then
        local result = vet(view)
        if result == false then
            return false
        end
    end
    if GetPluginOption("go", "golint") then
        return lint(view)
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

function togglegooption(option)
    if GetPluginOption("go", option) == true then
        messenger:Message(option .. " off")
        SetPluginOption("go", option, false)
    else
        messenger:Message(option .. " on")
        SetPluginOption("go", option, true)
    end
    WritePluginSettings("go")
end

function togglegoimports()
    togglegooption("goimports")
end

function togglegofmt()
    togglegooption("gofmt")
end

function togglegovet()
    togglegooption("govet")
end

function togglegolint()
    togglegooption("golint")
end

function list(str)
    lastpkg = ""
    ostr = str
    view = CurView()
    if str == "" or str == nil then
        ostr = ""
        str = "std"
    elseif string.find(str, "%.%.%.") == nil then
        str = str .. "..."
    end
    msg, err = ExecCommand("go", "list", str)
    if err ~= nil then
        msg, err = ExecCommand("go", "list", "std")
        found_lines = {}
        omsg = msg
        msg = ""
        for line in string.gmatch(omsg, "([^\n]*)\n?") do
            if string.find(line, ostr) then
                table.insert(found_lines, line)
            end
        end
        for i, line in ipairs(found_lines) do
            msg = msg .. line .. "\n"
        end
        if msg == "" then
            messenger:Warning("No module found for word: ", ostr)
            return false
        end
    end
    view:OpenHelperView("v", "", msg)
    view:PreviousSplit(false)
    return true
end

function doc(str)
    ostr = str
    view = CurView()
    if str == "" or str == nil then
        return true
    end
    if string.find(str, "%.") == nil then
        if lastpkg ~= "" then
            str = lastpkg .. "." .. str
        else
            lastpkg = str
        end
    else
        for pkg in string.gmatch(str, "%.") do
            lastpkg = pkg;
            break
        end
    end
    msg, err = ExecCommand("go", "doc", str)
    if err ~= nil then
        msg, err = ExecCommand("go", "doc", ostr)
        if err ~= nil then
            messenger:Warning("No method found for ", str, " (", ostr, ")")
            lastpkg = ""
            return true
        end
        lastpkg = ostr
    end
    if view:GetHelperView() ~= nil then
        view:CloseHelperView()
    end
    view:OpenHelperView("v", "godoc", msg)
    view:PreviousSplit(false)
    return true
end

function onDisplayFocus(view)
    MakeCommand("golist", "go.list", 0)
    MakeCommand("godoc", "go.doc", 0)
    BindKey("F7", "go.modernize")
    BindKey("F8", "go.modernizefix")
    BindKey("F9", "go.togglegofmt")
    BindKey("F10", "go.togglegovet")
    BindKey("F11", "go.togglegolint")
    BindKey("F12", "go.togglegoimports")
end

function onDisplayBlur(view)
    RemoveCommand("golist")
    RemoveCommand("godoc")
    BindKey("F7", "Unbindkey")
    BindKey("F9", "Unbindkey")
    BindKey("F10", "Unbindkey")
    BindKey("F11", "Unbindkey")
    BindKey("F12", "Unbindkey")
end

function onViewOpen(view)
    onDisplayFocus(view)
end

