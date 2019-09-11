VERSION = "1.0.0"

local curFileType = ""
local snippets = {}
local currentSnippet = nil
local autoclose = false

local Location = {}
Location.__index = Location

local Snippet = {}
Snippet.__index = Snippet

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
    if startChar == endChar then
        return ""
    end
    
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

-- replace UTF-8 characters based on a mapping table
function utf8replace (s, mapping)
    local pos = 1
    local bytes = string.len(s)
    local charbytes
    local newstr = ""

    while pos <= bytes do
        charbytes = utf8charbytes(s, pos)
        local c = string.sub(s, pos, pos + charbytes - 1)
        newstr = newstr .. (mapping[c] or c)
        pos = pos + charbytes
    end

    return newstr
end

function Location.new(idx, ph, snip)
	local self = setmetatable({}, Location)
	self.idx = idx
	self.ph = ph
	self.snippet = snip
	return self
end

-- offset of the location relative to the snippet start
function Location.offset(self)
	local add = 0
	for i = 1, #self.snippet.locations do
		local loc = self.snippet.locations[i]
		if loc == self then
			break
		end

		local val = loc.ph.value
		if val then
--			add = add + val:len()
			add = add + utf8len(val)
		end
	end
	return self.idx+add
end

function Location.startPos(self)
	local loc = self.snippet.startPos
	return loc:Move(self:offset(), self.snippet.view.buf)
end

-- returns the length of the location (but at least 1)
function Location.len(self)
	local len = 0
	if self.ph.value then
		len = utf8len(self.ph.value)
	end
	if len <= 0 then
		len = 1
	end
	return len
end

function Location.endPos(self)
	local start = self:startPos()
	return start:Move(self:len(), self.snippet.view.buf)
end

-- check if the given loc is within the location
function Location.isWithin(self, loc)
	return loc:GreaterEqual(self:startPos()) and loc:LessEqual(self:endPos())
end

function Location.focus(self)
	local view = self.snippet.view
	local startP = self:startPos():Move(-1, view.Buf)
	local endP = self:endPos():Move(-1, view.Buf)

	while view.Cursor:LessThan(startP) do
		view.Cursor:Right()
	end
	while view.Cursor:GreaterThan(endP) do
		view.Cursor:Left()
	end

	if utf8len(self.ph.value) > 0 then
		view.Cursor:SetSelectionStart(startP)
		view.Cursor:SetSelectionEnd(endP)
	else
		view.Cursor:ResetSelection()
	end
end

function Location.handleInput(self, ev)
	if ev.EventType == 1 then
		-- TextInput
		if ev.Deltas[1].Text == "\n" then
			Accept()
			return false
		else
			local offset = 1
			local sp = self:startPos()
			while sp:LessEqual(-ev.Deltas[1].Start) do
				sp = sp:Move(1, self.snippet.view.Buf)
				offset = offset + 1
			end

			self.snippet:remove()
			local v = self.ph.value
			if v == nil then
				v = ""
			end
			self.ph.value = utf8sub(v,0, offset-1) .. ev.Deltas[1].Text .. utf8sub(v,offset)
			self.snippet:insert()
			return true
		end
	elseif ev.EventType == -1 then
		-- TextRemove
		local offset = 1
		local sp = self:startPos()
		while sp:LessEqual(-ev.Deltas[1].Start) do
			sp = sp:Move(1, self.snippet.view.Buf)
			offset = offset + 1
		end

		if ev.Deltas[1].Start.Y ~= ev.Deltas[1].End.Y then
			return false
		end

		self.snippet:remove()

		local v = self.ph.value
		if v == nil then
			v = ""
		end

		local len = ev.Deltas[1].End.X - ev.Deltas[1].Start.X
		self.ph.value = utf8sub(v,0, offset-1) .. utf8sub(v,offset+len)
		self.snippet:insert()
		return true
	end

	return false
end

function Snippet.new()
	local self = setmetatable({}, Snippet)
	self.code = ""
	return self
end

function Snippet.AddCodeLine(self, line)
	if self.code ~= "" then
		self.code = self.code .. "\n"
	end
	self.code = self.code .. line
end

function Snippet.Prepare(self)
	if not self.placeholders then
		self.placeholders = {}
		self.locations = {}
		local count = 0
		local pattern = "${(%d+):?([^}]*)}"
		while true do
			local num, value = self.code:match(pattern)
			if not num then
				break
			end
			count = count+1
			num = tonumber(num)
			local idx = self.code:find(pattern)
			self.code = self.code:gsub(pattern, "", 1)

			local p = self.placeholders[num]
			if not p then
				p = {num = num}
				self.placeholders[#self.placeholders+1] = p
			end
			self.locations[#self.locations+1] = Location.new(idx, p, self)

			if value then
				p.value = value
			end
		end
	end
end

function Snippet.clone(self)
	local result = Snippet.new()
	result:AddCodeLine(self.code)
	result:Prepare()
	return result
end

function Snippet.str(self)
	local res = self.code
	local x
	for i = #self.locations, 1, -1 do
		local loc = self.locations[i]
		res = res:sub(0, loc.idx-1) .. loc.ph.value .. res:sub(loc.idx)
	end
	return res
end

function Snippet.findLocation(self, loc)
	for i = 1, #self.locations do
		if self.locations[i]:isWithin(loc) then
			return self.locations[i]
		end
	end
	return nil
end

function Snippet.remove(self)
	local endPos = self.startPos:Move(utf8len(self:str()), self.view.Buf)
	self.modText = true
	self.view.Cursor:SetSelectionStart(self.startPos)
	self.view.Cursor:SetSelectionEnd(endPos)
	self.view.Cursor:DeleteSelection()
	self.view.Cursor:ResetSelection()
	self.modText = false
end

function Snippet.insert(self)
	self.modText = true
	self.view.Buf:insert(self.startPos, self:str())
	self.modText = false
end

function Snippet.focusNext(self)
	if self.focused == nil then
		self.focused = 0
	else
		self.focused = (self.focused + 1) % #self.placeholders
	end

	local ph = self.placeholders[self.focused+1]

	for i = 1, #self.locations do
		if self.locations[i].ph == ph then
			self.locations[i]:focus()
			return
		end
	end
end

local function CursorWord(v)
	local c = v.Cursor
	local x = c.X-1 -- start one rune before the cursor
	local result = ""
	while x >= 0 do
		local r = RuneStr(c:RuneUnder(x))
		if IsWordChar(r) then
			result = r .. result
		else
			break
		end
		x = x-1
	end

	return result
end

local function ReadSnippets(filetype)
	local snippets = {}
	local allSnippetFiles = ListRuntimeFiles("snippets")
	local exists = false

	for i = 1, #allSnippetFiles do
		if allSnippetFiles[i] == filetype then
			exists = true
			break
		end
	end

	if not exists then
		messenger:Error("No snippets file for \""..filetype.."\"")
		return snippets
	end

	local snippetFile = ReadRuntimeFile("snippets", filetype)

	local curSnip = nil
	local lineNo = 0
	for line in string.gmatch(snippetFile, "(.-)\r?\n") do
		lineNo = lineNo + 1
		if string.match(line,"^#") then
			-- comment
		elseif line:match("^snippet") then
			curSnip = Snippet.new()
			for snipName in line:gmatch("%s(%a+)") do
				snippets[snipName] = curSnip
			end
		else
			local codeLine = line:match("^\t(.*)$")
			if codeLine ~= nil then
				curSnip:AddCodeLine(codeLine)
			elseif line ~= "" then
				messenger:Error("Invalid snippets file (Line #"..tostring(lineNo)..")")
			end
		end
	end
	return snippets
end

local function EnsureSnippets()
	local filetype = CurView().Buf:FileType()
	if curFileType ~= filetype then
		snippets = ReadSnippets(filetype)
		curFileType = filetype
	end
end

function onBeforeTextEvent(ev)
	if currentSnippet ~= nil and currentSnippet.view == CurView() then
		if currentSnippet.modText then
			-- text event from the snippet. simply ignore it...
			return true
		end

		local locStart = nil
		local locEnd = nil

        if ev.Deltas[1].Start ~= nil and currentSnippet ~= nil then
			locStart = currentSnippet:findLocation(ev.Deltas[1].Start:Move(1, CurView().Buf))
			locEnd = currentSnippet:findLocation(ev.Deltas[1].End)
		end
		if locStart ~= nil and ((locStart == locEnd) or (ev.Deltas[1].End.Y==0 and ev.Deltas[1].End.X==0))  then
			if locStart:handleInput(ev) then
				CurView().Cursor:Goto(-ev.C)
				return false
			end
		end
		Accept()
	end

	return true

end

function Insert(name)
	local v = CurView()
	local c = v.Cursor
	local buf = v.Buf
	local xy = Loc(c.X, c.Y)
	local noArg = false
	if not name then
		name = CursorWord(v)
		noArg = true
	end

	EnsureSnippets()
	local curSn = snippets[name]
	if curSn then
		currentSnippet = curSn:clone()
		currentSnippet.view = v

		if noArg then
			currentSnippet.startPos = xy:Move(-name:len(), buf)

			currentSnippet.modText = true

			c:SetSelectionStart(currentSnippet.startPos)
			c:SetSelectionEnd(xy)
			c:DeleteSelection()
			c:ResetSelection()

			currentSnippet.modText = false
		else
			currentSnippet.startPos = xy
		end

		currentSnippet:insert()

		if #currentSnippet.placeholders == 0 then
			local pos = currentSnippet.startPos:Move(currentSnippet:str():len(), v.Buf)
			while v.Cursor:LessThan(pos) do
				v.Cursor:Right()
			end
			while v.Cursor:GreaterThan(pos) do
				v.Cursor:Left()
			end
		else
			currentSnippet:focusNext()
		end
		if GetOption("autoclose")==true then
			-- Disable autoclose during snippet edit, it conflicts
			autoclose=true
			SetLocalOption("autoclose","false",v)
		end
	else
		messenger:Message("Unknown snippet \""..name.."\"")
	end
end

function Next()
	if currentSnippet then
		currentSnippet:focusNext()
	end
end

function Accept()
	if autoclose==true then
		-- Enable autoclose after snippet edit ends
		SetLocalOption("autoclose","true",CurView())
	end
	currentSnippet = nil
end

function Cancel()
	if currentSnippet then
		currentSnippet:remove()
		Accept()
	end
end


local function StartsWith(String,Start)
  String = String:upper()
  Start = Start:upper()
  return string.sub(String,1,string.len(Start))==Start
end

function findSnippet(input)
	local result = {}
	EnsureSnippets()

	for name,v in pairs(snippets) do
		if StartsWith(name, input) then
			table.insert(result, name)
		end
	end
	return result
end

-- Insert a snippet
MakeCommand("snippetinsert", "snippets.Insert", MakeCompletion("snippets.findSnippet"), 0)
-- Mark next placeholder
MakeCommand("snippetnext", "snippets.Next", 0)
-- Cancel current snippet (removes the text)
MakeCommand("snippetcancel", "snippets.Cancel", 0)
-- Acceptes snipped editing
MakeCommand("snippetaccept", "snippets.Accept", 0)

AddRuntimeFile("snippets", "help", "help/snippets.md")
AddRuntimeFilesFromDirectory("snippets", "snippets", "snippets", "*.snippets")

BindKey("Alt-w", "snippets.Next")
BindKey("Alt-a", "snippets.Accept")
BindKey("Alt-s", "snippets.Insert")
BindKey("Alt-d", "snippets.Cancel")
