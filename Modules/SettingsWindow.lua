--[[
	Just Setting
]] 

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, SettingsWindow, Notebook -- Major Apps
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
	SettingsWindow = Apps.SettingsWindow
	Notebook = Apps.Notebook
end

local function main()
    local SettingsWindow = {}
    
	SettingsWindow.Init = function()
		local window = Lib.Window.new()
		window:SetTitle("Settings")
		window:Resize(320, 500)
		SettingsWindow.Window = window
		
		-- ListFrame
		
		ListFrame = Instance.new("ScrollingFrame")
		ListFrame.Parent = window.GuiElems.Content
		ListFrame.Size = UDim2.new(1, 0,1, -30)
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
		
		local function AddSeperator(title)
			local frame = Lib.Frame.new()
			frame.Gui.Parent = ListFrame
			frame.Gui.Transparency = 1
			frame.Gui.Size = UDim2.new(1,0,0,25)
			
			local label = Lib.Label.new()
			label.Parent = frame.Gui
			label.Size = UDim2.new(1, 0, 1, 0)
			label.Text = title
			label.TextSize = 16
			label.TextColor3 = Color3.fromRGB(200,200,200)
			label.Font = Enum.Font.SourceSansBold
			label.TextTruncate = Enum.TextTruncate.AtEnd
			return label
		end
		
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
			label.Parent = frame.Gui
			label.Size = UDim2.new(1, 0,1, -15)
			label.Text = title
			label.TextTruncate = Enum.TextTruncate.AtEnd
			
			checkbox:SetState(default or false)
			return checkbox
		end
		
		local function AddTextbox(title, default, sizeX)
			default = default and tostring(default) or ""
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
			textbox.Size = UDim2.new(0, sizeX or 45, 0, 18)
			
			frame.Gui.AutomaticSize = Enum.AutomaticSize.X

			local label = Lib.Label.new()
			label.Parent = frame.Gui
			label.Size = UDim2.new(1, 0,1, -15)
			label.Text = title
			label.TextTruncate = Enum.TextTruncate.AtEnd

			textbox.Text = default
			return textbox
		end
		
		local function AddDropdown(title, options, default, allowEmpty, sizeX)
			if allowEmpty == nil then allowEmpty = true end
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

			local dropdown = Lib.DropDown.new()
			dropdown.CanBeEmpty = allowEmpty
			dropdown.Size = UDim2.new(0, sizeX or 75, 0, 18)
			dropdown:SetOptions(options)
			if default then dropdown:SetSelected(default) end
			dropdown.Gui.Parent = frame.Gui

			frame.Gui.AutomaticSize = Enum.AutomaticSize.X

			local label = Lib.Label.new()
			label.Parent = frame.Gui
			label.Size = UDim2.new(1, 0,1, -15)
			label.Text = title
			label.TextTruncate = Enum.TextTruncate.AtEnd
			
			return dropdown
		end
		
		local function AddColorPicker(title, tableRef, key)
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

			local colorBtn = Instance.new("TextButton")
			colorBtn.Size = UDim2.new(0, 50, 0, 18)
			colorBtn.BackgroundColor3 = tableRef[key]
			colorBtn.BorderColor3 = Color3.fromRGB(15,15,15)
			colorBtn.Text = ""
			colorBtn.Parent = frame.Gui

			local label = Lib.Label.new()
			label.Parent = frame.Gui
			label.Size = UDim2.new(1, -65, 1, 0)
			label.Text = title
			label.TextTruncate = Enum.TextTruncate.AtEnd

			colorBtn.Activated:Connect(function()
				local picker = Lib.ColorPicker.new()
				picker.Window:SetTitle("Edit: " .. title)
				picker:SetColor(tableRef[key])
				picker.OnSelect:Connect(function(col)
					tableRef[key] = col
					colorBtn.BackgroundColor3 = col
				end)
				picker.Window:ShowAndFocus()
			end)
		end

		SettingsWindow.ReloadPrompt = function()		
			local win = ScriptViewer.ReloadPromptWindow
			if not win then
				win = Lib.Window.new()
				win.Alignable = false
				win.Resizable = false
				win:SetTitle("Apply Current Settings")
				win:SetSize(300,115)
	
				local reloadButton = Lib.Button.new()
				local nameLabel = Lib.Label.new()
				nameLabel.Text = "By applying current settings requires reload.\nAny unsaved progress will be lost.\nAre you sure?"
				nameLabel.Position = UDim2.new(0,30,0,20)
				nameLabel.Size = UDim2.new(0,40,0,20)
				win:Add(nameLabel)
	
				local cancelButton = Lib.Button.new()
				cancelButton.AnchorPoint = Vector2.new(1,1)
				cancelButton.Text = "Apply Later"
				cancelButton.Position = UDim2.new(1,-5,1,-5)
				cancelButton.Size = UDim2.new(0.5,-10,0,20)
				cancelButton.OnClick:Connect(function()
					win:Close()
				end)
				win:Add(cancelButton)
	
				reloadButton.Text = "Apply Now"
				reloadButton.AnchorPoint = Vector2.new(0,1)
				reloadButton.Position = UDim2.new(0,5,1,-5)
				reloadButton.Size = UDim2.new(0.5,-5,0,20)
				reloadButton.OnClick:Connect(function()
					Main.Reinit()
				end)
	
				win:Add(reloadButton,"reloadButton")
	
				SettingsWindow.ReloadPromptWindow = win
			end
			win:Show()
		end

		AddSeperator("UI & General")
		local classIcon = AddDropdown("Class Icons", {"Old", "NewDark", "Vanilla3"}, Settings.ClassIcon, false, 100)
		classIcon.OnSelect:Connect(function() Settings.ClassIcon = classIcon.Selected end)
		
		AddSeperator("Explorer")
		local clickRename = AddCheckbox("Click to Rename", Settings.Explorer.ClickToRename)
		clickRename.OnInput:Connect(function() Settings.Explorer.ClickToRename = clickRename.Toggled end)

		local explorerSorting = AddCheckbox("Enable Sorting", Settings.Explorer.Sorting)
		explorerSorting.OnInput:Connect(function() Settings.Explorer.Sorting = explorerSorting.Toggled end)

		local autoUpdateSearch = AddCheckbox("Auto Update Search", Settings.Explorer.AutoUpdateSearch)
		autoUpdateSearch.OnInput:Connect(function() Settings.Explorer.AutoUpdateSearch = autoUpdateSearch.Toggled end)

		local updateModeOpts = {"0: Default", "1: No Tree Update", "2: No Events", "3: Frozen"}
		local currentUpdateMode = updateModeOpts[Settings.Explorer.AutoUpdateMode + 1] or updateModeOpts[1]
		local updateModeDrop = AddDropdown("Auto Update Mode", updateModeOpts, currentUpdateMode, false, 110)
		updateModeDrop.OnSelect:Connect(function() Settings.Explorer.AutoUpdateMode = tonumber(string.sub(updateModeDrop.Selected, 1, 1)) or 0 end)
		
		local partSelectionBox = AddCheckbox("Part Selection Box", Settings.Explorer.PartSelectionBox)
		partSelectionBox.OnInput:Connect(function() Settings.Explorer.PartSelectionBox = partSelectionBox.Toggled end)

		local guiSelectionBox = AddCheckbox("GUI Selection Box", Settings.Explorer.GuiSelectionBox)
		guiSelectionBox.OnInput:Connect(function() Settings.Explorer.GuiSelectionBox = guiSelectionBox.Toggled end)
		
		local copypathUseChildren = AddCheckbox("Use GetChildren for Copy Path", Settings.Explorer.CopyPathUseGetChildren)
		copypathUseChildren.OnInput:Connect(function() Settings.Explorer.CopyPathUseGetChildren = copypathUseChildren.Toggled end)
		
		AddSeperator("Properties")
		local scaleOpts = {"0: Full Name Shown", "1: Equal Halves"}
		local currentScale = scaleOpts[Settings.Properties.ScaleType + 1] or scaleOpts[1]
		local scaleTypeDrop = AddDropdown("Scale Type", scaleOpts, currentScale, false, 120)
		scaleTypeDrop.OnSelect:Connect(function() Settings.Properties.ScaleType = tonumber(string.sub(scaleTypeDrop.Selected, 1, 1)) or 0 end)

		local showDeprecated = AddCheckbox("Show Deprecated", Settings.Properties.ShowDeprecated)
		showDeprecated.OnInput:Connect(function() Settings.Properties.ShowDeprecated = showDeprecated.Toggled end)
		
		local showHidden = AddCheckbox("Show Hidden", Settings.Properties.ShowHidden)
		showHidden.OnInput:Connect(function() Settings.Properties.ShowHidden = showHidden.Toggled end)
		
		local showAttributes = AddCheckbox("Show Attributes", Settings.Properties.ShowAttributes)
		showAttributes.OnInput:Connect(function() Settings.Properties.ShowAttributes = showAttributes.Toggled end)

		local clearOnFocus = AddCheckbox("Clear On Focus", Settings.Properties.ClearOnFocus)
		clearOnFocus.OnInput:Connect(function() Settings.Properties.ClearOnFocus = clearOnFocus.Toggled end)

		local loadstringInput = AddCheckbox("Enable Loadstring Input", Settings.Properties.LoadstringInput)
		loadstringInput.OnInput:Connect(function() Settings.Properties.LoadstringInput = loadstringInput.Toggled end)

		local maxConflictBox = AddTextbox("Max Conflict Check", Settings.Properties.MaxConflictCheck, 50)
		maxConflictBox.FocusLost:Connect(function() local num = tonumber(maxConflictBox.Text) if num then Settings.Properties.MaxConflictCheck = num end end)

		local maxAttrBox = AddTextbox("Max Attributes to Load", Settings.Properties.MaxAttributes, 50)
		maxAttrBox.FocusLost:Connect(function() local num = tonumber(maxAttrBox.Text) if num then Settings.Properties.MaxAttributes = num end end)

		local numRoundingBox = AddTextbox("Number Rounding (Decimals)", Settings.Properties.NumberRounding, 50)
		numRoundingBox.FocusLost:Connect(function() local num = tonumber(numRoundingBox.Text) if num then Settings.Properties.NumberRounding = num end end)
		
		AddSeperator("Theme - General Colors")
		AddColorPicker("Main 1 (Backgrounds)", Settings.Theme, "Main1")
		AddColorPicker("Main 2 (Secondary)", Settings.Theme, "Main2")
		AddColorPicker("Outline 1 (Frames)", Settings.Theme, "Outline1")
		AddColorPicker("Outline 2 (Buttons)", Settings.Theme, "Outline2")
		AddColorPicker("Outline 3 (TextBoxes)", Settings.Theme, "Outline3")
		AddColorPicker("TextBox BG", Settings.Theme, "TextBox")
		AddColorPicker("Menu BG", Settings.Theme, "Menu")
		AddColorPicker("List Selection", Settings.Theme, "ListSelection")
		AddColorPicker("Button Regular", Settings.Theme, "Button")
		AddColorPicker("Button Hover", Settings.Theme, "ButtonHover")
		AddColorPicker("Button Press", Settings.Theme, "ButtonPress")
		AddColorPicker("Highlight", Settings.Theme, "Highlight")
		AddColorPicker("Text Default", Settings.Theme, "Text")
		AddColorPicker("Placeholder Text", Settings.Theme, "PlaceholderText")
		AddColorPicker("Important (Errors)", Settings.Theme, "Important")

		AddSeperator("Theme - Syntax Highlighting")
		AddColorPicker("Text Default", Settings.Theme.Syntax, "Text")
		AddColorPicker("Background", Settings.Theme.Syntax, "Background")
		AddColorPicker("Selection Text", Settings.Theme.Syntax, "Selection")
		AddColorPicker("Selection BG", Settings.Theme.Syntax, "SelectionBack")
		AddColorPicker("Operator", Settings.Theme.Syntax, "Operator")
		AddColorPicker("Number", Settings.Theme.Syntax, "Number")
		AddColorPicker("String", Settings.Theme.Syntax, "String")
		AddColorPicker("Comment", Settings.Theme.Syntax, "Comment")
		AddColorPicker("Keyword", Settings.Theme.Syntax, "Keyword")
		AddColorPicker("Error", Settings.Theme.Syntax, "Error")
		AddColorPicker("Find Background", Settings.Theme.Syntax, "FindBackground")
		AddColorPicker("Matching Word", Settings.Theme.Syntax, "MatchingWord")
		AddColorPicker("Built-in Function", Settings.Theme.Syntax, "BuiltIn")
		AddColorPicker("Current Line BG", Settings.Theme.Syntax, "CurrentLine")
		AddColorPicker("Local Method", Settings.Theme.Syntax, "LocalMethod")
		AddColorPicker("Local Property", Settings.Theme.Syntax, "LocalProperty")
		AddColorPicker("Nil", Settings.Theme.Syntax, "Nil")
		AddColorPicker("Boolean (true/false)", Settings.Theme.Syntax, "Bool")
		AddColorPicker("Function Keyword", Settings.Theme.Syntax, "Function")
		AddColorPicker("Local Keyword", Settings.Theme.Syntax, "Local")
		AddColorPicker("Self Keyword", Settings.Theme.Syntax, "Self")
		AddColorPicker("Function Name", Settings.Theme.Syntax, "FunctionName")
		AddColorPicker("Bracket ()[]{}", Settings.Theme.Syntax, "Bracket")

		local BackgroundreloadButton = Lib.Frame.new()
		BackgroundreloadButton.Gui.Parent = window.GuiElems.Content
		BackgroundreloadButton.Size = UDim2.new(1,0, 0,30)
		BackgroundreloadButton.Position = UDim2.new(0,0, 1,-30)
		
		local LabelreloadButton = Lib.Label.new()
		LabelreloadButton.Gui.Parent = window.GuiElems.Content
		LabelreloadButton.Size = UDim2.new(1,0, 0,20)
		LabelreloadButton.Position = UDim2.new(0,0, 1,-20)
		LabelreloadButton.Gui.Text = "Restart"
		LabelreloadButton.Gui.TextXAlignment = Enum.TextXAlignment.Center
		
		local reloadButton = Instance.new("TextButton")
		reloadButton.Parent = BackgroundreloadButton.Gui
		reloadButton.Size = UDim2.new(1,0, 1,0)
		reloadButton.Position = UDim2.new(0,0, 0,0)
		reloadButton.Transparency = 1
		
		reloadButton.MouseButton1Click:Connect(function()
			window:SetTitle("Settings - Saving")
			
			Main.SaveCurrentSettings()
			
			window:SetTitle("Settings - Saved")
			SettingsWindow.ReloadPrompt()
			task.wait(3)
			
			window:SetTitle("Settings")
		end)
	end

	return SettingsWindow
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}