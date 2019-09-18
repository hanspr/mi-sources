
VERSION="1.0.0"

myapp = nil

function application()
	myapp = GetPluginApp()
	if myapp == nil  then
		return
	end
	myapp:New("test-app")
	width = 55
	height = 10
	
	myapp:AddStyle("def","#ffffff,#262626")
	myapp:AddStyle("red","bold #ff0000,#262626")
	myapp:AddStyle("green","underline #00ff00,#262626")
	
	f = myapp:AddFrame("f", -1, -1, width, height, "relative")
	
	f:AddWindowBox("test", "Test Plugin", 0, 0, width, height, true, ButtonFinish, "def","")
	f:AddWindowTextBox("name","Name: ","","",1,2,12,10,nil,"def","")
	f:AddWindowLabel("lblstudies","Your studies",1,4,nil,"red","")
	f:AddWindowRadio("study","Elementary","1",1,5,false,nil,"def","")
	f:AddWindowRadio("study","Highschool","2",1,6,true,nil,"def","")
	f:AddWindowRadio("study","Other","3",1,7,false,nil,"def","")
	
	f:AddWindowLabel("likes","What you like",20,4,nil,"green","")
	f:AddWindowCheckBox("like","Swim","Sw",20,5,false,nil,"def","")
	f:AddWindowCheckBox("like","TV","Tv",20,6,false,nil,"def","")
	f:AddWindowCheckBox("like","Games","Gm",20,7,false,nil,"def","")

	f:AddWindowSelect("sh","Favorite super hero: ","Antman","Antman|Batman|Catwoman|Iron man|Superman|Thor|Zorro",22,2,0,1,nil,"def","")

	f:AddWindowButton("OK"," Ok button ","ok",width-16, height-1,nil,"","test.ButtonFinish")
	
	RunPluginApp(myapp)
end

function ButtonFinish(name, value, event, when, x, y)
	if event ~= "mouse-click1" then
		return true
	end
	if when == "POST" then
		return true
	end
	messenger:AddLog("Values selected by user")
	values = GetLuaTable(myapp:GetValuesAsString())
	for k,v in pairs(values) do
		messenger:AddLog(k .. ":" .. v)
	end
	StopPluginApp(myapp)
	myapp = nil
end

function Load()
	BindKey("F24", "test.application")
end

Load()

