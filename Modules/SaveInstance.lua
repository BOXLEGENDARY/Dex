--[[
	Save Instance App Module
	
	Revival of the old dex's Save Instance
]] 

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, SaveInstance, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings
	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	SaveInstance = Apps.SaveInstance
	Notebook = Apps.Notebook
end

local function main()
	local SaveInstance = {}
	local window, ListFrame
	local placeName = "Place_"..game.PlaceId
	pcall(function() placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
	local fileName = env.parsefile(placeName) .. "_{TIMESTAMP}"
	
	local SaveInstanceArgs = {
		SafeMode = true,
		KillAllScripts = true,
		BoostFPS = false,
		ShutdownWhenDone = false,
		AntiIdle = true,
		Anonymous = false,
		ShowStatus = true,
		ReadMe = true,
		AlternativeWritefile = true,
		AvoidFileOverwrite = true,
		mode = "optimized",
		SaveCacheInterval = 22528,
		Decompile = true,
		scriptcache = true,
		DecompileTimeout = 10,
		DecompileJobless = false,
		SaveBytecode = false,
		NilInstances = false,
		IgnoreDefaultProperties = true,
		IgnoreNotArchivable = true,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		IgnoreSpecialProperties = false,
		IgnoreDefaultPlayerScripts = true,
		IgnoreSharedStrings = true,
		SharedStringOverwrite = false,
		TreatUnionsAsParts = false,
		IsolateStarterPlayer = false,
		IsolatePlayers = false,
		IsolateLocalPlayer = false,
		IsolateLocalPlayerCharacter = false,
		SavePlayerCharacters = false,
		SaveNotCreatable = false,
		DecompileIgnore = {"TextChatService"},
		IgnoreList = {"CoreGui", "CorePackages"},
		IgnoreProperties = {}
	}
	
	local function AddCheckbox(title, default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)
		
		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)
		
		local checkbox = Lib.Checkbox.new()
		checkbox.Gui.Parent = frame.Gui
		checkbox.Gui.Size = UDim2.new(0,15,0,15)
		
		local label = Lib.Label.new()
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, 0,1, -15)
		label.Gui.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		
		checkbox:SetState(default)
		return checkbox
	end
	
	local function AddTextbox(title, default, sizeX)
		default = tostring(default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.Transparency = 1
		frame.Gui.Size = UDim2.new(1,0,0,20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		local textbox = Instance.new("TextBox")
		textbox.BackgroundColor3 = Settings.Theme.TextBox
		textbox.BorderColor3 = Settings.Theme.Outline3
		textbox.ClearTextOnFocus = false
		textbox.TextColor3 = Settings.Theme.Text
		textbox.Font = Enum.Font.SourceSans
		textbox.TextSize = 14
		textbox.ZIndex = 2
		textbox.Parent = frame.Gui
		textbox.Size = sizeX and UDim2.new(0,sizeX,0,15) or UDim2.new(0,45,0,15)
		
		frame.Gui.AutomaticSize = Enum.AutomaticSize.X
		textbox.AutomaticSize = Enum.AutomaticSize.X

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0,1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd
		textbox.Text = default
		return {TextBox = textbox}
	end
	
	SaveInstance.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Save Instance")
		window:Resize(350,350)
		SaveInstance.Window = window
		
		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0,1, -40)
		ListFrame.Position = UDim2.new(0, 0, 0, 0)
		ListFrame.Transparency = 1
		ListFrame.CanvasSize = UDim2.new(0,0,0,0)
		ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ListFrame.ScrollBarThickness = 16
		ListFrame.BottomImage = ""
		ListFrame.TopImage = ""
		ListFrame.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
		ListFrame.ScrollBarImageTransparency = 0
		ListFrame.ZIndex = 2
		ListFrame.BorderSizePixel = 0
		
		local scrollbar = Lib.ScrollBar.new()
		scrollbar.Gui.Parent = window.GuiElems.Content
		scrollbar.Gui.Size = UDim2.new(1, 0,1, -40)
		scrollbar.Gui.Up.ZIndex = 3
		scrollbar.Gui.Down.ZIndex = 3
		
		ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			scrollbar.Gui.Visible = ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize
		end)
		
		local ListLayout = Instance.new("UIListLayout")
		ListLayout.Parent = ListFrame
		ListLayout.Padding = UDim.new(0, 5)
		
		local Padding = Instance.new("UIPadding")
		Padding.Parent = ListFrame
		Padding.PaddingBottom = UDim.new(0, 5)
		Padding.PaddingLeft = UDim.new(0, 10)
		Padding.PaddingRight = UDim.new(0, 10)
		Padding.PaddingTop = UDim.new(0, 5)
		
		local BooleanOptions = {
			{"Safe Mode", "SafeMode"},
			{"Kill All Scripts", "KillAllScripts"},
			{"Boost FPS", "BoostFPS"},
			{"Shutdown When Done", "ShutdownWhenDone"},
			{"Anti-Idle", "AntiIdle"},
			{"Anonymous Mode", "Anonymous"},
			{"Show Status", "ShowStatus"},
			{"Include ReadMe", "ReadMe"},
			{"Alternative Writefile", "AlternativeWritefile"},
			{"Avoid File Overwrite", "AvoidFileOverwrite"},
			{"Decompile Scripts", "Decompile"},
			{"Use Script Cache", "scriptcache"},
			{"Decompile Jobless", "DecompileJobless"},
			{"Save Bytecode", "SaveBytecode"},
			{"Save Nil Instances", "NilInstances"},
			{"Ignore Default Properties", "IgnoreDefaultProperties"},
			{"Ignore Not Archivable", "IgnoreNotArchivable"},
			{"Ignore Non-Script Props (Scripts Mode)", "IgnorePropertiesOfNotScriptsOnScriptsMode"},
			{"Ignore Special Properties", "IgnoreSpecialProperties"},
			{"Ignore Default PlayerScripts", "IgnoreDefaultPlayerScripts"},
			{"Ignore Shared Strings", "IgnoreSharedStrings"},
			{"Shared String Overwrite", "SharedStringOverwrite"},
			{"Treat Unions As Parts", "TreatUnionsAsParts"},
			{"Isolate StarterPlayer", "IsolateStarterPlayer"},
			{"Isolate Players", "IsolatePlayers"},
			{"Isolate LocalPlayer", "IsolateLocalPlayer"},
			{"Isolate LocalPlayer Character", "IsolateLocalPlayerCharacter"},
			{"Save Player Characters", "SavePlayerCharacters"},
			{"Save Not Creatable", "SaveNotCreatable"}
		}

		local TextOptions = {
			{"Mode (optimized/full/scripts)", "mode", 70},
			{"Decompile Timeout (s)", "DecompileTimeout", 30},
			{"Save Cache Interval", "SaveCacheInterval", 50}
		}

		local ListOptions = {
			{"Decompile Ignore", "DecompileIgnore", 100},
			{"Ignore List", "IgnoreList", 100},
			{"Ignore Properties", "IgnoreProperties", 100}
		}

		for _, opt in ipairs(BooleanOptions) do
			local cb = AddCheckbox(opt[1], SaveInstanceArgs[opt[2]])
			cb.OnInput:Connect(function()
				SaveInstanceArgs[opt[2]] = cb.Toggled
			end)
		end

		for _, opt in ipairs(TextOptions) do
			local tb = AddTextbox(opt[1], tostring(SaveInstanceArgs[opt[2]]), opt[3])
			tb.TextBox.FocusLost:Connect(function()
				local text = tb.TextBox.Text
				if type(SaveInstanceArgs[opt[2]]) == "number" then
					SaveInstanceArgs[opt[2]] = tonumber(text) or SaveInstanceArgs[opt[2]]
				else
					SaveInstanceArgs[opt[2]] = text
				end
			end)
		end

		for _, opt in ipairs(ListOptions) do
			local tb = AddTextbox(opt[1], table.concat(SaveInstanceArgs[opt[2]], ","), opt[3])
			tb.TextBox.FocusLost:Connect(function()
				local inputText = tb.TextBox.Text
				local rawList = string.split(inputText, ",")
				local finalList = {}
				for _, text in ipairs(rawList) do
					local clean = string.match(text, "^%s*(.-)%s*$")
					if clean and clean ~= "" then
						table.insert(finalList, clean)
					end
				end
				SaveInstanceArgs[opt[2]] = finalList
			end)
		end
		
		local FilenameTextBox = Lib.ViewportTextBox.new()
		FilenameTextBox.Gui.Parent = window.GuiElems.Content
		FilenameTextBox.Size = UDim2.new(1,0, 0,20)
		FilenameTextBox.Position = UDim2.new(0,0, 1,-40)
		
		local textpadding = Instance.new("UIPadding")
		textpadding.Parent = FilenameTextBox.Gui
		textpadding.PaddingLeft = UDim.new(0, 5)
		textpadding.PaddingRight = UDim.new(0, 5)
		
		local BackgroundButton = Lib.Frame.new()
		BackgroundButton.Gui.Parent = window.GuiElems.Content
		BackgroundButton.Size = UDim2.new(1,0, 0,20)
		BackgroundButton.Position = UDim2.new(0,0, 1,-20)
		
		local LabelButton = Lib.Label.new()
		LabelButton.Gui.Parent = window.GuiElems.Content
		LabelButton.Size = UDim2.new(1,0, 0,20)
		LabelButton.Position = UDim2.new(0,0, 1,-20)
		LabelButton.Gui.Text = "Save"
		LabelButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local Button = Instance.new("TextButton")
		Button.Parent = BackgroundButton.Gui
		Button.Size = UDim2.new(1,0, 1,0)
		Button.Position = UDim2.new(0,0, 0,0)
		Button.Transparency = 1
		
		FilenameTextBox.TextBox.Text = fileName
		Button.MouseButton1Click:Connect(function()
			local fileNamePath = FilenameTextBox.TextBox.Text:gsub("{TIMESTAMP}", os.date("%Y%m%d_%H%M%S"))
			if not fileNamePath:match("^dex/saved/") then
				fileNamePath = "dex/saved/" .. fileNamePath
			end
			window:SetTitle("Save Instance - Saving")
			local s, result = pcall(env.saveinstance, game, fileNamePath, SaveInstanceArgs)
			if s then
				window:SetTitle("Save Instance - Saved")
			else
				window:SetTitle("Save Instance - Error")
				task.spawn(error, "Failed to save the game: " .. tostring(result))
			end
			task.wait(5)
			window:SetTitle("Save Instance")
		end)
	end

	return SaveInstance
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
