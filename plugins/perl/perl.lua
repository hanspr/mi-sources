
VERSION = "1.0.0"

local ErrorView = nil
local curLoc = {}
local writesettings = false

if GetPluginOption("perl","perlsyntaxstrict") == nil then
	AddPluginOption("perl","perlsyntaxstrict", false)
	writesettings = true
end

if GetPluginOption("perl","perlsyntax") == nil then
	AddPluginOption("perl","perlsyntax", true)
	writesettings = true
end

if GetPluginOption("perl","version") == nil then
	AddPluginOption("perl","version", VERSION)
	writesettings = true
elseif GetPluginOption("perl","version") ~= VERSION then
	SetPluginOption("perl","version", VERSION)
	writesettings = true
end

if writesettings then
	WritePluginSettings("perl")
end

AddRuntimeFile("perl", "help", "help/perl-plugin.md")

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
	BindKey("F10", "perl.perlsyntaxoff")
	BindKey("AltEnter", "perl.addcomma")
end

function eol()
	CurView().Cursor:End()
end

function addcomma()
	view = CurView()
	xy = {}
	xy.X = view.Cursor.Loc.X
	xy.Y = view.Cursor.Loc.Y
	line = view.Buf:Line(xy.Y)
	if string.find(line,";$") then
		return true
	end
	view.Cursor:End()
	curLoc.X = view.Cursor.Loc.X
	curLoc.Y = view.Cursor.Loc.Y
	view.Buf:Insert(curLoc, ";")
	--view.Cursor:GotoLoc(xy)
end

function formatbuffer(view)
	if CurView().Buf.IsModified == true then
		CurView():Save(false)
	end
	local spc = "0"
	local num = "0"
	if (GetOption("indentchar") == " ") then
		spc = "1";
		num = GetOption("tabsize")
	end
	local handle = io.popen("perl ~/.config/mi-ide/plugins/perl/formatbuffer.pl '" .. CurView().Buf.Path .. "' " .. spc .. " " .. num)
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

function perlsyntaxoff()
	if GetPluginOption("perl","perlsyntax") == true then
		messenger:Message("perl syntax off")
		SetPluginOption("perl","perlsyntax",false)
	else
		messenger:Message("perl syntax on")
		SetPluginOption("perl","perlsyntax",true)
	end
	WritePluginSettings("perl")
end

function perlCheck(view,fpath)
	local ps = 0
	local pcheck
	local scheck

	if GetPluginOption("perl","perlsyntax") == false then
		return true
	end
	if GetPluginOption("perl","perlsyntaxstrict") == true then
		msg,err=ExecCommand("perl","-cw","-Mstrict",fpath)
		pcheck = "Strict"
	else
		msg,err=ExecCommand("perl","-cX",fpath)
		pcheck = "Dirty"
	end
	if err ~= nil or string.find(msg,"line") ~= nil then
		if pcheck == "Strict" then
			scheck = "error"
		elseif string.find(msg,"syntax OK") ~= nil then
			scheck = "ok"
		else
			scheck = "error"
		end
	else
		scheck = "ok"
	end
	if scheck ~= "ok" then
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
			view:Relocate()
		end
		messenger:Error("Syntax Error")
		return false
	else
		if ErrorView ~= nil then
			ErrorView:Quit(false)
			if curLoc.Y ~= -1 and curLoc.Y ~= CurView().Cursor.Loc.Y then
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

-- Insert ; at the end of lines to avoid typing it
-- Use Alt Enter to avoid going to the end after for the new line

function onBackspace(view)
	if view.Buf:Line(view.Cursor.Loc.Y)==";" then
		view:Delete(false)
	end
end


