
VERSION = "1.0.0"

local ErrorView = nil
local curLoc = {}
local addcomma = true

if GetPluginOption("perl","perlsyntaxstrict") == nil then
	AddPluginOption("perl","perlsyntaxstrict", false)
end

if GetPluginOption("perl","addcomma") == nil then
	AddPluginOption("perl","addcomma", true)
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
	BindKey("F9", "perl.togglecommas")
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

function togglecommas()
	local view = CurView()
	if GetPluginOption("perl","addcomma") == true then
		SetPluginOption("perl","addcomma",false)
		addcomma = false
		messenger:Message("addcomma = false")
		xy = view.Cursor.Loc
		cloc={}
		cloc.X=xy.X
		cloc.Y=xy.Y
		lstart = {}
		lstart.X=0
		lstart.Y=xy.Y
		line = view.Buf:Line(xy.Y)
		l=utf8len(line)
		lend = {}
		lend.X=l
		lend.Y=xy.Y
		lchar = utf8sub(line,-1)
		if lchar==";" then
			line = utf8sub(line,1,-2)
			view.Buf:Replace(lstart,lend,line)
			view.Cursor:GotoLoc(cloc)
		end
	else
		SetPluginOption("perl","addcomma",true)
		messenger:Message("addcomma = true")
		addcomma = true
		onRune("",view)
	end
	WritePluginSettings("perl")
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
			view:Relocate()
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
	addcomma = GetPluginOption("perl","addcomma")
    onDisplayFocus(view)
end

-- Insert ; at the end of lines to avoid typing it
-- Use Alt Enter to avoid going to the end after for the new line

function onBackspace(view)
	if view.Buf:Line(view.Cursor.Loc.Y)==";" then
		view:Delete(false)
	end
end

function onRune(char,view)
	if addcomma==false then
		return true
	end
	xy = view.Cursor.Loc
	cloc={}
	cloc.X=xy.X
	cloc.Y=xy.Y
	lstart = {}
	lstart.X=0
	lstart.Y=xy.Y
	line = view.Buf:Line(xy.Y)
	l=utf8len(line)
	lend = {}
	lend.X=l
	lend.Y=xy.Y
	lchar = utf8sub(line,-1)
	if lchar==";" then
		lchar = utf8sub(line,-2,-1)
		if lchar=="{;" or (lchar=="};" and char ~= ";") or lchar=="(;" or lchar==",;" or lchar==";;" then
			line = utf8sub(line,1,-2)
			view.Buf:Replace(lstart,lend,line)
			view.Cursor:GotoLoc(cloc)
		end
		return true
	end
	if lchar=="{" or lchar=="}" or lchar=="(" or lchar=="," or lchar==";" then 
		return true
	end
	line = line .. ";"
	view.Buf:Replace(lstart,lend,line)
	view.Cursor:GotoLoc(cloc)
	return true
end

-- returns the number of bytes used by the UTF-8 character at byte i in s
-- also doubles as a UTF-8 character validator
function utf8charbytes (s, i)
    -- argument defaults
    i = i or 1
    local c = string.byte(s, i)

    -- determine bytes needed for character, based on RFC 3629
    if c > 0 and c <= 127 then
        -- UTF8-1
        return 1
    elseif c >= 194 and c <= 223 then
        -- UTF8-2
        local c2 = string.byte(s, i + 1)
        return 2
    elseif c >= 224 and c <= 239 then
        -- UTF8-3
        local c2 = s:byte(i + 1)
        local c3 = s:byte(i + 2)
        return 3
    elseif c >= 240 and c <= 244 then
        -- UTF8-4
        local c2 = s:byte(i + 1)
        local c3 = s:byte(i + 2)
        local c4 = s:byte(i + 3)
        return 4
    end
end

-- returns the number of characters in a UTF-8 string
function utf8len (s)
    local pos = 1
    local bytes = string.len(s)
    local len = 0

    while pos <= bytes and len ~= chars do
        local c = string.byte(s,pos)
        len = len + 1

        pos = pos + utf8charbytes(s, pos)
    end

    if chars ~= nil then
        return pos - 1
    end

    return len
end

-- functions identically to string.sub except that i and j are UTF-8 characters
-- instead of bytes
function utf8sub (s, i, j)
    j = j or -1

    if i == nil then
        return ""
    end

    local pos = 1
    local bytes = string.len(s)
    local len = 0

    -- only set l if i or j is negative
    local l = (i >= 0 and j >= 0) or utf8len(s)
    local startChar = (i >= 0) and i or l + i + 1
    local endChar = (j >= 0) and j or l + j + 1


    -- Want's nothing
--    if startChar == endChar then
--        return ""
--    end
    
    -- can't have start before end!
    if startChar > endChar then
        return ""
    end

    -- byte offsets to pass to string.sub
    local startByte, endByte = 1, bytes

    while pos <= bytes do
        len = len + 1

        if len == startChar then
            startByte = pos
        end

        pos = pos + utf8charbytes(s, pos)

        if len == endChar then
            endByte = pos - 1
            break
        end
    end

    return string.sub(s, startByte, endByte)
end


