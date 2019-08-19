
VERSION = "1.0.0"

local ErrorView = nil
local curLoc = {}

if GetPluginOption("perl","perlsyntaxstrict") == nil then
	AddPluginOption("perl","perlsyntaxstrict", false)
end

function preQuit(view)
    if ErrorView ~= nil  then
        ErrorView:Quit(false)
        ErrorView = nil
        return false
    end
end

function setperlstrict()
	BindKey("F12", "perl.togglestrict")
	BindKey("F11", "perl.formatbuffer")
end

function formatbuffer(view)
	if CurView().Buf.IsModified == true then
		CurView():Save(false)
	end
    local handle = io.popen("perl ~/.config/micro-ide/plugins/perl/formatbuffer.pl '" .. CurView().Buf.Path .. "'")
    local result = handle:read("*a")
    handle:close()
    CurView().Buf.IsModified=false
    CurView():ReOpen()
end

function togglestrict()
	if GetPluginOption("perl","perlsyntaxstrict") == true then
		messenger:Message("perl Dirty")
		SetPluginOption("perl","perlsyntaxstrict",false)
	else
		messenger:Message("perl Strict")
		SetPluginOption("perl","perlsyntaxstrict",true)
	end
	WritePluginSettings("perl")
end

function perlCheck(view,fpath)
    local ps = 0
	local pcheck
	
	if GetPluginOption("perl","perlsyntaxstrict") == true then
		msg,err=ExecCommand("perl","-cw","-Mstrict",fpath)
		pcheck = "Strict"
	else
		msg,err=ExecCommand("perl","-c",fpath)
		pcheck = "Dirty"
	end
	if err ~= nil or string.find(msg,"line") ~= nil then
--		messenger:Error(msg)
        if ErrorView == nil then
        	curLoc.X = view.Cursor.Loc.X
        	curLoc.Y = view.Cursor.Loc.Y
            view:HSplitIndex(NewBuffer(msg, "Error"), 1)
            ErrorView = CurView()
            ErrorView.Type.Kind=2
            ErrorView.Type.Readonly = true
            ErrorView.Type.Scratch = true
            SetLocalOption("softwrap", "true", ErrorView)
            SetLocalOption("ruler", "false", ErrorView)
            SetLocalOption("autosave", "false", ErrorView)
            SetLocalOption("statusline", "false", ErrorView)
            SetLocalOption("scrollbar", "false", ErrorView)
            ps = 1
        else
            ErrorView.Buf:remove({0,0},ErrorView.Buf:End())
            ErrorView.Buf:insert({0,0},msg)
        end
        ErrorView.Cursor:GotoLoc({0,0})
		if ps==1 then
		    view:PreviousSplit(false)
	    end
		local xy={}
		xy.X = 0
		xy.Y = -99
		if string.find(msg,"EOF") == nil then
			for ch in string.gmatch(msg,"line (%d+)") do
				xy.Y = tonumber(ch)-1;
				break
			end
		end
		if xy.Y ~= -99  then
			if xy.Y<0 then
				xy.Y=0
			end
			view.Cursor:GotoLoc(xy)
			view:Center(false)
		end
		messenger:Error("Syntax Error")
		return false
	else
	    if ErrorView ~= nil then
	        ErrorView:Quit(false)
	        if curLoc.Y ~= -1 then
			    view.Cursor:GotoLoc(curLoc)
			    curLoc.Y = -1
	        end
			view:Center(false)
	    end
        ErrorView = nil
	end
	messenger:Success(msg .. " (" .. pcheck .. ")")
	return true
end

function onSave(view)
	local fpath = CurView().Buf.Path

	return perlCheck(view,fpath)
end

function onDisplayFocus(view)
	setperlstrict()
end

function onViewOpen(view)
    onDisplayFocus(view)
end

function onOpen(view)
    onDisplayFocus(view)
end

