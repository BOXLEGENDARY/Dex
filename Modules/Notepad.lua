--[[
	Notepad App Module
	
	A notepad
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notepad, Notebook -- Major Apps
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
	Notepad = Apps.Notepad
	Notebook = Apps.Notebook
end

local function main()
	local Notepad = {}
	local window, codeFrame

	Notepad.Init = function()
	    window = Lib.Window.new()
	    window:SetTitle("Notepad")
	    window:Resize(500, 400)
	    Notepad.Window = window
	
	    local tabBar = Instance.new("ScrollingFrame", window.GuiElems.Content)
	    tabBar.Size = UDim2.new(1, -25, 0, 20)
	    tabBar.BackgroundTransparency = 1
	    tabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
	    tabBar.ScrollBarThickness = 0
	    
	    local tabLayout = Instance.new("UIListLayout", tabBar)
	    tabLayout.FillDirection = Enum.FillDirection.Horizontal
	    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	
	    local addTabBtn = Instance.new("TextButton", window.GuiElems.Content)
	    addTabBtn.Size = UDim2.new(0, 25, 0, 20)
	    addTabBtn.Position = UDim2.new(1, -25, 0, 0)
	    addTabBtn.Text = "+"
	    addTabBtn.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
	    addTabBtn.TextColor3 = Color3.new(1, 1, 1)
	    addTabBtn.BorderSizePixel = 0
	
		local openedTabs = {}
		local activeTab = nil
		
		local function getAvailableTabNumber()
		    local i = 1
		    while true do
		        local found = false
		        for _, tab in pairs(openedTabs) do
		            if tab.Name == "Tab " .. tostring(i) then
		                found = true
		                break
		            end
		        end
		        if not found then
		            return i
		        end
		        i = i + 1
		    end
		end
		
		local function createTab(initialText, tabName, filePath)
		    if not tabName then
		        tabName = "Tab " .. tostring(getAvailableTabNumber())
		    end
		    
		    local tabObj = {
		        Name = tabName,
		        FilePath = filePath
		    }
		    table.insert(openedTabs, tabObj)
		    
		    local btn = Instance.new("TextButton", tabBar)
		    btn.Size = UDim2.new(0, 100, 1, 0)
		    btn.Text = ""
		    btn.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		    btn.BorderSizePixel = 0
		    
		    local titleLabel = Instance.new("TextLabel", btn)
		    titleLabel.Size = UDim2.new(1, -25, 1, 0)
		    titleLabel.Position = UDim2.new(0, 5, 0, 0)
		    titleLabel.BackgroundTransparency = 1
		    titleLabel.Text = tabName
		    titleLabel.TextColor3 = Color3.new(1, 1, 1)
		    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
		    
		    local closeBtn = Instance.new("TextButton", btn)
		    closeBtn.Size = UDim2.new(0, 15, 1, 0)
		    closeBtn.Position = UDim2.new(1, -15, 0, 0)
		    closeBtn.BackgroundTransparency = 1
		    closeBtn.Text = "X"
		    closeBtn.TextColor3 = Color3.new(1, 0, 0)
		    
		    local cf = Lib.CodeFrame.new()
		    cf.Frame.Position = UDim2.new(0, 0, 0, 20)
		    cf.Frame.Size = UDim2.new(1, 0, 1, -40)
		    cf.Frame.Parent = window.GuiElems.Content
		    cf.Frame.Visible = false
		    
		    tabObj.Button = btn
		    tabObj.TitleLabel = titleLabel
		    tabObj.CodeFrame = cf
		    
		    if initialText then 
		        cf:SetText(initialText) 
		    end
		    
		    btn.MouseButton1Click:Connect(function()
		        if activeTab then
		            activeTab.CodeFrame.Frame.Visible = false
		            activeTab.Button.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		        end
		        activeTab = tabObj
		        activeTab.CodeFrame.Frame.Visible = true
		        activeTab.Button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
		    end)
		    
		    closeBtn.MouseButton1Click:Connect(function()
		        if #openedTabs <= 1 then return end
		        
		        for i, t in ipairs(openedTabs) do
		            if t == tabObj then
		                table.remove(openedTabs, i)
		                break
		            end
		        end
		        
		        cf.Frame:Destroy()
		        btn:Destroy()
		        
		        if activeTab == tabObj then
		            local lastTab = openedTabs[#openedTabs]
		            if lastTab then
		                activeTab = lastTab
		                activeTab.CodeFrame.Frame.Visible = true
		                activeTab.Button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
		            else
		                activeTab = nil
		            end
		        end
		        
		        local totalWidth = 0
		        for _, v in ipairs(openedTabs) do
		            totalWidth = totalWidth + v.Button.AbsoluteSize.X
		        end
		        tabBar.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
		    end)
		    
		    if activeTab then
		        activeTab.CodeFrame.Frame.Visible = false
		        activeTab.Button.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
		    end
		    activeTab = tabObj
		    activeTab.CodeFrame.Frame.Visible = true
		    activeTab.Button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
		    
		    local totalWidth = 0
		    for _, v in ipairs(openedTabs) do
		        totalWidth = totalWidth + v.Button.AbsoluteSize.X
		    end
		    tabBar.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
		    
		    return tabObj
		end
		
		addTabBtn.MouseButton1Click:Connect(function()
		    createTab()
		end)
		
		local saveBtn = Instance.new("TextButton", window.GuiElems.Content)
		saveBtn.BackgroundTransparency = 1
		saveBtn.Size = UDim2.new(0.25, 0, 0, 20)
		saveBtn.Position = UDim2.new(0, 0, 1, -20)
		saveBtn.Text = "Save"
		saveBtn.TextColor3 = Color3.new(1, 1, 1)
		
		saveBtn.MouseButton1Click:Connect(function()
		    if activeTab then
		        local source = activeTab.CodeFrame:GetText()
		        if activeTab.FilePath then
		            if env.writefile then
		                env.writefile(activeTab.FilePath, source)
		            end
		        else
		            if env.writefile then
		                local filename = "dex/saved/Notepad_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
		                env.writefile(filename, source)
		                activeTab.FilePath = filename
		                local shortName = filename:match("([^/]+)$") or filename
		                activeTab.Name = shortName
		                if activeTab.TitleLabel then
		                    activeTab.TitleLabel.Text = shortName
		                else
		                    activeTab.Button.Text = shortName
		                end
		            end
		        end
		    end
		end)
		
		local openBtn = Instance.new("TextButton", window.GuiElems.Content)
		openBtn.BackgroundTransparency = 1
		openBtn.Size = UDim2.new(0.25, 0, 0, 20)
		openBtn.Position = UDim2.new(0.25, 0, 1, -20)
		openBtn.Text = "Open"
		openBtn.TextColor3 = Color3.new(1, 1, 1)
		
		local fileMenu = Instance.new("ScrollingFrame", window.GuiElems.Content)
		fileMenu.Size = UDim2.new(0.5, 0, 0.5, 0)
		fileMenu.Position = UDim2.new(0.25, 0, 0.4, 0)
		fileMenu.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
		fileMenu.BorderSizePixel = 1
		fileMenu.BorderColor3 = Color3.fromRGB(60, 60, 60)
		fileMenu.Visible = false
		fileMenu.ZIndex = 10
		
		local uiListLayout = Instance.new("UIListLayout", fileMenu)
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		
		openBtn.MouseButton1Click:Connect(function()
		    fileMenu.Visible = not fileMenu.Visible
		    if not fileMenu.Visible then return end
		    
		    for _, child in pairs(fileMenu:GetChildren()) do
		        if child:IsA("TextButton") then 
		            child:Destroy() 
		        end
		    end
		    
		    if env.listfiles then
		        local files = env.listfiles("dex/saved") or {}
		        for _, filePath in pairs(files) do
		            local fileName = filePath:match("([^/]+)$") or filePath
		            
		            local fileItem = Instance.new("TextButton", fileMenu)
		            fileItem.Size = UDim2.new(1, 0, 0, 25)
		            fileItem.Text = " " .. fileName
		            fileItem.TextXAlignment = Enum.TextXAlignment.Left
		            fileItem.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		            fileItem.TextColor3 = Color3.new(1, 1, 1)
		            fileItem.ZIndex = 11
		            
		            fileItem.MouseButton1Click:Connect(function()
		                fileMenu.Visible = false
		                if env.readfile then
		                    local content = env.readfile(filePath)
		                    createTab(content, fileName, filePath)
		                end
		            end)
		        end
		    else
		        warn("Executor does not support listfiles")
		    end
		end)
		
		local clearBtn = Instance.new("TextButton", window.GuiElems.Content)
		clearBtn.BackgroundTransparency = 1
		clearBtn.Size = UDim2.new(0.25, 0, 0, 20)
		clearBtn.Position = UDim2.new(0.50, 0, 1, -20)
		clearBtn.Text = "Clear"
		clearBtn.TextColor3 = Color3.new(1, 1, 1)
		
		clearBtn.MouseButton1Click:Connect(function()
		    if activeTab then
		        activeTab.CodeFrame:SetText("")
		    end
		end)
		
		local executeBtn = Instance.new("TextButton", window.GuiElems.Content)
		executeBtn.BackgroundTransparency = 1
		executeBtn.Size = UDim2.new(0.25, 0, 0, 20)
		executeBtn.Position = UDim2.new(0.75, 0, 1, -20)
		executeBtn.Text = "Execute"
		executeBtn.TextColor3 = Color3.new(1, 1, 1)
		
		executeBtn.MouseButton1Click:Connect(function()
		    if activeTab then
		        local source = activeTab.CodeFrame:GetText()
		        local func, err = loadstring(source)
		        if func then
		            task.spawn(func)
		        else
		            warn("Compile Error: " .. tostring(err))
		        end
		    end
		end)

		Notepad.OpenInTab = function(code, name, filePath)
		    if not Notepad.Window:IsContentVisible() then
		        Notepad.Window:Show()
		    end
		    Notepad.Window:Focus()
		    createTab(code, name, filePath)
		end	
	end

	return Notepad
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}