
VERSION = "1.0.0"

local ErrorView = nil
local writesettings = false

if GetPluginOption("go","version") == nil then
	AddPluginOption("go","version", VERSION)
	writesettings = true
elseif GetPluginOption("go","version") ~= VERSION then
	SetPluginOption("go","version", VERSION)
	writesettings = true
end

if GetPluginOption("go","goimports") == nil then
    AddPluginOption("go","goimports", false)
	writesettings = true
end

if GetPluginOption("go","gofmt") == nil then
    AddPluginOption("go","gofmt", true)
	writesettings = true
end

if writesettings then
	WritePluginSettings("go")
end

MakeCommand("goimports", "go.goimports", 0)
MakeCommand("gofmt", "go.gofmt", 0)
AddRuntimeFile("go", "help", "help/go-plugin.md")

function onSave(view)
    if GetPluginOption("go","goimports") then
        goimports()
    end
    if GetPluginOption("go","gofmt") then
        return gofmt(view)
    end
end

function gofmt(view)
    local ps = 0
    
	msg,err=ExecCommand("gofmt","-e",CurView().Buf.Path)
    if err ~= nil then
        if ErrorView == nil then
            view:HSplitIndex(NewBuffer(msg, "Error"), 1)
            ErrorView = CurView()
            ErrorView.Type.Kind=2
            ErrorView.Type.Readonly = true
            ErrorView.Type.Scratch = true
            SetLocalOption("softwrap", "true", ErrorView)
            SetLocalOption("ruler", "false", ErrorView)
            SetLocalOption("softwrap", "true", ErrorView)
            SetLocalOption("autosave", "false", ErrorView)
            SetLocalOption("statusline", "false", ErrorView)
            SetLocalOption("scrollbar", "false", ErrorView)
            SetLocalOption("ruler", "false", ErrorView)
            SetLocalOption("autosave", "false", ErrorView)
            SetLocalOption("statusline", "false", ErrorView)
            SetLocalOption("scrollbar", "false", ErrorView)
            ps = 1
        else
            local pos = ErrorView.Buf:Start()
            ErrorView.Buf:deleteToEnd(pos)
            ErrorView.Buf:insert(pos,msg)
        end
		local xy={}
		xy.X = 0
		xy.Y = -99
		for ch in string.gmatch(msg,"(%d+):") do
			xy.Y = tonumber(ch)-1;
			break
		end
		if xy.Y ~= -99  then
			if xy.Y<0 then
				xy.Y=0
			end
			if ps==1 then
			    view:PreviousSplit(false)
		    end
			view.Cursor:GotoLoc(xy)
		end
		messenger:Error("Syntax Error")
		return false
    else
	    if ErrorView ~= nil then
	        ErrorView:Quit(false)
	    end
        ErrorView = nil
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


