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
	local placeName = "Place_" .. game.PlaceId
	pcall(function()
		placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	end)

	local fileName = env.parsefile(placeName) .. "_{TIMESTAMP}"
	local Saving = false

	local SaveInstanceArgs = {
		SaveBytecode = false,
		Callback = false,
		ShowStatus = true,
		IgnoreDefaultPlayerScripts = true,

		NilInstancesFixes = {
			BaseWrap = false,
			Animator = false,
			Attachment = false,
			PackageLink = false,
			AdPortal = false,
		},

		IgnoreList = {"Chat", "CoreGui", "CorePackages"},
		__DEBUG_MODE = false,
		KillAllScripts = true,
		DecompileJobless = false,
		IgnoreNotArchivable = true,
		RemovePlayerCharacters = true,
		Object = game,
		DecompileIgnore = {"TextChatService"},
		IgnoreSpecialProperties = false,
		TreatUnionsAsParts = false,
		IsModel = false,
		NilInstances = false,
		ExtraInstances = {},
		noscripts = false,
		ReadMe = true,

		OptionsAliases = {
			SavePlayers = "IsolatePlayers",
			IgnoreArchivable = "IgnoreNotArchivable",
			DecompileTimeout = "timeout",
			SaveNonCreatable = "SaveNotCreatable",
			InstancesBlacklist = "IgnoreList",
			IsolatePlayerGui = "IsolateLocalPlayer",
			FileName = "FilePath",
			IgnoreDefaultProps = "IgnoreDefaultProperties",
		},

		scriptcache = true,
		SharedStringOverwrite = false,
		AlternativeWritefile = true,
		mode = "optimized",
		SaveCacheInterval = 56320,
		IgnoreSharedStrings = true,
		IsolatePlayers = false,
		NotCreatableFixes = {"", "AdvancedDragger", "AnimationTrack", "Dragger", "Player", "PlayerGui", "PlayerMouse", "PlayerScripts", "ScreenshotHud", "StudioData", "TextChatMessage", "TextSource", "TouchTransmitter", "Translator"},
		timeout = 10,
		IgnoreDefaultProperties = true,
		Anonymous = false,
		IsolateStarterPlayer = false,
		IsolateLocalPlayerCharacter = false,
		IgnorePropertiesOfNotScriptsOnScriptsMode = false,
		AvoidFileOverwrite = true,
		SaveNotCreatable = false,
		IsolateLocalPlayer = false,
		FilePath = "dex/saved/" .. fileName,
		AntiIdle = true,
		ShutdownWhenDone = false,
		SafeMode = true,
		IgnoreProperties = {}
	}

	local function AddSeperator(title)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.BackgroundTransparency = 1
		frame.Gui.Size = UDim2.new(1, 0, 0, 25)

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Text = title
		label.TextSize = 16
		label.TextColor3 = Color3.fromRGB(200, 200, 200)
		label.Font = Enum.Font.SourceSansBold
		label.TextTruncate = Enum.TextTruncate.AtEnd
		return label
	end

	local function AddDropdown(title, options, default, allowEmpty, sizeX)
		if allowEmpty == nil then allowEmpty = true end

		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.BackgroundTransparency = 1
		frame.Gui.Size = UDim2.new(1, 0, 0, 20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		local dropdown = Lib.DropDown.new()
		dropdown.CanBeEmpty = allowEmpty
		dropdown.Size = UDim2.new(0, sizeX or 75, 0, 18)
		dropdown:SetOptions(options)
		if default then
			dropdown:SetSelected(default)
		end
		dropdown.Gui.Parent = frame.Gui

		frame.Gui.AutomaticSize = Enum.AutomaticSize.X

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0, 1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		return dropdown
	end

	local function AddCheckbox(title, default)
		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.BackgroundTransparency = 1
		frame.Gui.Size = UDim2.new(1, 0, 0, 20)

		local listlayout = Instance.new("UIListLayout")
		listlayout.Parent = frame.Gui
		listlayout.FillDirection = Enum.FillDirection.Horizontal
		listlayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		listlayout.VerticalAlignment = Enum.VerticalAlignment.Center
		listlayout.Padding = UDim.new(0, 10)

		local checkbox = Lib.Checkbox.new()
		checkbox.Gui.Parent = frame.Gui
		checkbox.Gui.Size = UDim2.new(0, 15, 0, 15)

		local label = Lib.Label.new()
		label.Gui.Parent = frame.Gui
		label.Gui.Size = UDim2.new(1, 0, 1, -15)
		label.Gui.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		checkbox:SetState(default)
		return checkbox
	end

	local function AddTextbox(title, default, sizeX)
		default = tostring(default)

		local frame = Lib.Frame.new()
		frame.Gui.Parent = ListFrame
		frame.Gui.BackgroundTransparency = 1
		frame.Gui.Size = UDim2.new(1, 0, 0, 20)

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

		if sizeX and type(sizeX) == "number" then
			textbox.Size = UDim2.new(0, sizeX, 0, 15)
		else
			textbox.Size = UDim2.new(0, 45, 0, 15)
		end

		frame.Gui.AutomaticSize = Enum.AutomaticSize.X
		textbox.AutomaticSize = Enum.AutomaticSize.X

		local label = Lib.Label.new()
		label.Parent = frame.Gui
		label.Size = UDim2.new(1, 0, 1, -15)
		label.Text = title
		label.TextTruncate = Enum.TextTruncate.AtEnd

		textbox.Text = default
		return {TextBox = textbox}
	end

	SaveInstance.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Save Instance")
		window:Resize(380, 500)
		SaveInstance.Window = window

		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0, 1, -40)
		ListFrame.Position = UDim2.new(0, 0, 0, 0)
		ListFrame.BackgroundTransparency = 1
		ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
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
		scrollbar.Gui.Size = UDim2.new(1, 0, 1, -40)
		scrollbar.Gui.Up.ZIndex = 3
		scrollbar.Gui.Down.ZIndex = 3

		ListFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
			if ListFrame.AbsoluteCanvasSize ~= ListFrame.AbsoluteWindowSize then
				scrollbar.Gui.Visible = true
			else
				scrollbar.Gui.Visible = false
			end
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

		AddSeperator("General Settings")
		local modeDrop = AddDropdown("Mode", {"optimized", "full", "scripts"}, SaveInstanceArgs.mode, false, 80)
		modeDrop.OnSelect:Connect(function(val)
			SaveInstanceArgs.mode = val
		end)

		local ShowStat = AddCheckbox("Show Status", SaveInstanceArgs.ShowStatus)
		ShowStat.OnInput:Connect(function()
			SaveInstanceArgs.ShowStatus = ShowStat.Toggled
		end)

		local ReadMeBox = AddCheckbox("Generate ReadMe", SaveInstanceArgs.ReadMe)
		ReadMeBox.OnInput:Connect(function()
			SaveInstanceArgs.ReadMe = ReadMeBox.Toggled
		end)

		local AvoidFileOverwriteBox = AddCheckbox("Avoid File Overwrite", SaveInstanceArgs.AvoidFileOverwrite)
		AvoidFileOverwriteBox.OnInput:Connect(function()
			SaveInstanceArgs.AvoidFileOverwrite = AvoidFileOverwriteBox.Toggled
		end)

		local AlternativeWritefileBox = AddCheckbox("Alternative Writefile", SaveInstanceArgs.AlternativeWritefile)
		AlternativeWritefileBox.OnInput:Connect(function()
			SaveInstanceArgs.AlternativeWritefile = AlternativeWritefileBox.Toggled
		end)

		local AnonymousBox = AddCheckbox("Anonymous Mode", SaveInstanceArgs.Anonymous)
		AnonymousBox.OnInput:Connect(function()
			SaveInstanceArgs.Anonymous = AnonymousBox.Toggled
		end)

		AddSeperator("Protection & Safety")
		local SafeModeBox = AddCheckbox("Safe Mode (Kick before saving)", SaveInstanceArgs.SafeMode)
		SafeModeBox.OnInput:Connect(function()
			SaveInstanceArgs.SafeMode = SafeModeBox.Toggled
		end)

		local KillAllScriptsBox = AddCheckbox("Kill All Scripts", SaveInstanceArgs.KillAllScripts)
		KillAllScriptsBox.OnInput:Connect(function()
			SaveInstanceArgs.KillAllScripts = KillAllScriptsBox.Toggled
		end)

		local AntiIdleBox = AddCheckbox("Anti Idle", SaveInstanceArgs.AntiIdle)
		AntiIdleBox.OnInput:Connect(function()
			SaveInstanceArgs.AntiIdle = AntiIdleBox.Toggled
		end)

		local ShutdownWhenDoneBox = AddCheckbox("Shutdown When Done", SaveInstanceArgs.ShutdownWhenDone)
		ShutdownWhenDoneBox.OnInput:Connect(function()
			SaveInstanceArgs.ShutdownWhenDone = ShutdownWhenDoneBox.Toggled
		end)

		AddSeperator("Decompilation")
		local Decompile = AddCheckbox("Decompile Scripts", SaveInstanceArgs.noscripts)
		Decompile.OnInput:Connect(function()
			SaveInstanceArgs.noscripts = Decompile.Toggled
			SaveInstanceArgs.Decompile = Decompile.Toggled
		end)

		local SaveBytecodeBox = AddCheckbox("Save Bytecode", SaveInstanceArgs.SaveBytecode)
		SaveBytecodeBox.OnInput:Connect(function()
			SaveInstanceArgs.SaveBytecode = SaveBytecodeBox.Toggled
		end)

		local DecompileJoblessBox = AddCheckbox("Decompile Jobless", SaveInstanceArgs.DecompileJobless)
		DecompileJoblessBox.OnInput:Connect(function()
			SaveInstanceArgs.DecompileJobless = DecompileJoblessBox.Toggled
		end)

		local decompileTimeout = AddTextbox("Decompile Timeout (s)", SaveInstanceArgs.timeout, 25)
		decompileTimeout.TextBox.FocusLost:Connect(function()
			SaveInstanceArgs.timeout = tonumber(decompileTimeout.TextBox.Text) or 10
		end)

		local decompileIgnore = AddTextbox("Decompile Ignore", table.concat(SaveInstanceArgs.DecompileIgnore, ", "), 150)
		decompileIgnore.TextBox.FocusLost:Connect(function()
			local rawList = string.split(decompileIgnore.TextBox.Text, ",")
			local finalList = {}
			for _, text in ipairs(rawList) do
				local clean = string.match(text, "^%s*(.-)%s*$")
				if clean and #clean > 0 then
					table.insert(finalList, clean)
				end
			end
			SaveInstanceArgs.DecompileIgnore = finalList
		end)

		AddSeperator("Instances & Isolation")
		local IgnoreList = AddTextbox("Ignore List", table.concat(SaveInstanceArgs.IgnoreList, ", "), 150)
		IgnoreList.TextBox.FocusLost:Connect(function()
			local rawList = string.split(IgnoreList.TextBox.Text, ",")
			local finalList = {}
			for _, text in ipairs(rawList) do
				local clean = string.match(text, "^%s*(.-)%s*$")
				if clean and #clean > 0 then
					table.insert(finalList, clean)
				end
			end
			SaveInstanceArgs.IgnoreList = finalList
		end)

		local NilObj = AddCheckbox("Save Nil Instances", SaveInstanceArgs.NilInstances)
		NilObj.OnInput:Connect(function()
			SaveInstanceArgs.NilInstances = NilObj.Toggled
		end)

		local SaveNotCreatableBox = AddCheckbox("Save Not Creatable", SaveInstanceArgs.SaveNotCreatable)
		SaveNotCreatableBox.OnInput:Connect(function()
			SaveInstanceArgs.SaveNotCreatable = SaveNotCreatableBox.Toggled
		end)

		local RemovePlayerChar = AddCheckbox("Remove Player Characters", SaveInstanceArgs.RemovePlayerCharacters)
		RemovePlayerChar.OnInput:Connect(function()
			SaveInstanceArgs.RemovePlayerCharacters = RemovePlayerChar.Toggled
		end)

		local IsolateLocalPlayerBox = AddCheckbox("Isolate Local Player", SaveInstanceArgs.IsolateLocalPlayer)
		IsolateLocalPlayerBox.OnInput:Connect(function()
			SaveInstanceArgs.IsolateLocalPlayer = IsolateLocalPlayerBox.Toggled
		end)

		local IsolateStarterPlr = AddCheckbox("Isolate StarterPlayer", SaveInstanceArgs.IsolateStarterPlayer)
		IsolateStarterPlr.OnInput:Connect(function()
			SaveInstanceArgs.IsolateStarterPlayer = IsolateStarterPlr.Toggled
		end)

		local IsolateLocalPlayerCharacterBox = AddCheckbox("Isolate Local Player Character", SaveInstanceArgs.IsolateLocalPlayerCharacter)
		IsolateLocalPlayerCharacterBox.OnInput:Connect(function()
			SaveInstanceArgs.IsolateLocalPlayerCharacter = IsolateLocalPlayerCharacterBox.Toggled
		end)

		local IsolatePlayersBox = AddCheckbox("Isolate All Players", SaveInstanceArgs.IsolatePlayers)
		IsolatePlayersBox.OnInput:Connect(function()
			SaveInstanceArgs.IsolatePlayers = IsolatePlayersBox.Toggled
		end)

		AddSeperator("Advanced Fixes & Properties")
		local IgnoreDefaultProps = AddCheckbox("Ignore Default Properties", SaveInstanceArgs.IgnoreDefaultProperties)
		IgnoreDefaultProps.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreDefaultProperties = IgnoreDefaultProps.Toggled
		end)

		local IgnoreNotArchivableBox = AddCheckbox("Ignore Not Archivable", SaveInstanceArgs.IgnoreNotArchivable)
		IgnoreNotArchivableBox.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreNotArchivable = IgnoreNotArchivableBox.Toggled
		end)

		local IgnoreSpecialPropertiesBox = AddCheckbox("Ignore Special Properties", SaveInstanceArgs.IgnoreSpecialProperties)
		IgnoreSpecialPropertiesBox.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreSpecialProperties = IgnoreSpecialPropertiesBox.Toggled
		end)

		local IgnorePropertiesOfNotScriptsOnScriptsModeBox = AddCheckbox("Ignore Properties Of Not Scripts (Scripts Mode)", SaveInstanceArgs.IgnorePropertiesOfNotScriptsOnScriptsMode)
		IgnorePropertiesOfNotScriptsOnScriptsModeBox.OnInput:Connect(function()
			SaveInstanceArgs.IgnorePropertiesOfNotScriptsOnScriptsMode = IgnorePropertiesOfNotScriptsOnScriptsModeBox.Toggled
		end)

		local IgnoreDefaultPlayerScriptsBox = AddCheckbox("Ignore Default Player Scripts", SaveInstanceArgs.IgnoreDefaultPlayerScripts)
		IgnoreDefaultPlayerScriptsBox.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreDefaultPlayerScripts = IgnoreDefaultPlayerScriptsBox.Toggled
		end)

		local IgnoreSharedStringsBox = AddCheckbox("Ignore Shared Strings (Fixes Crashes)", SaveInstanceArgs.IgnoreSharedStrings)
		IgnoreSharedStringsBox.OnInput:Connect(function()
			SaveInstanceArgs.IgnoreSharedStrings = IgnoreSharedStringsBox.Toggled
		end)

		local SharedStringOverwriteBox = AddCheckbox("Shared String Overwrite", SaveInstanceArgs.SharedStringOverwrite)
		SharedStringOverwriteBox.OnInput:Connect(function()
			SaveInstanceArgs.SharedStringOverwrite = SharedStringOverwriteBox.Toggled
		end)

		local TreatUnionsAsPartsBox = AddCheckbox("Treat Unions As Parts", SaveInstanceArgs.TreatUnionsAsParts)
		TreatUnionsAsPartsBox.OnInput:Connect(function()
			SaveInstanceArgs.TreatUnionsAsParts = TreatUnionsAsPartsBox.Toggled
		end)

		local DebugModeBox = AddCheckbox("Debug Mode (Log Unusual Scenarios)", SaveInstanceArgs.__DEBUG_MODE)
		DebugModeBox.OnInput:Connect(function()
			SaveInstanceArgs.__DEBUG_MODE = DebugModeBox.Toggled
		end)

		local FilenameTextBox = Lib.ViewportTextBox.new()
		FilenameTextBox.Gui.Parent = window.GuiElems.Content
		FilenameTextBox.Size = UDim2.new(1, 0, 0, 20)
		FilenameTextBox.Position = UDim2.new(0, 0, 1, -40)

		local textpadding = Instance.new("UIPadding")
		textpadding.Parent = FilenameTextBox.Gui
		textpadding.PaddingLeft = UDim.new(0, 5)
		textpadding.PaddingRight = UDim.new(0, 5)

		local BackgroundButton = Lib.Frame.new()
		BackgroundButton.Gui.Parent = window.GuiElems.Content
		BackgroundButton.Gui.BackgroundTransparency = 1
		BackgroundButton.Size = UDim2.new(1, 0, 0, 20)
		BackgroundButton.Position = UDim2.new(0, 0, 1, -20)

		local LabelButton = Lib.Label.new()
		LabelButton.Gui.Parent = window.GuiElems.Content
		LabelButton.Size = UDim2.new(1, 0, 0, 20)
		LabelButton.Position = UDim2.new(0, 0, 1, -20)
		LabelButton.Gui.Text = "Save"
		LabelButton.Gui.TextXAlignment = Enum.TextXAlignment.Center

		local Button = Instance.new("TextButton")
		Button.Parent = BackgroundButton.Gui
		Button.Size = UDim2.new(1, 0, 1, 0)
		Button.Position = UDim2.new(0, 0, 0, 0)
		Button.BackgroundTransparency = 1
		Button.Text = ""

		FilenameTextBox.TextBox.Text = fileName

		Button.MouseButton1Click:Connect(function()
			local resolvedName = FilenameTextBox.TextBox.Text:gsub("{TIMESTAMP}", os.date("%Y%m%d_%H%M%S"))

			if not resolvedName:match("^dex/saved/") then
				resolvedName = "dex/saved/" .. resolvedName
			end

			SaveInstanceArgs.FilePath = resolvedName
			SaveInstanceArgs.Object = game

			window:SetTitle("Save Instance - Saving")

			local s, result = pcall(function()
				env.saveinstance(SaveInstanceArgs)
			end)

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