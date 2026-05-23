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
	
	    local tabs = {}
	    local activeTab = nil
	    local tabCounter = 0
	
	    local function switchTab(tabObj)
	        if activeTab then
	            activeTab.CodeFrame.Frame.Visible = false
	            activeTab.Button.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	        end
	        activeTab = tabObj
	        activeTab.CodeFrame.Frame.Visible = true
	        activeTab.Button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
	    end
	
	    local function createTab()
	        tabCounter = tabCounter + 1
	        local tabObj = {}
	        
	        local btn = Instance.new("TextButton", tabBar)
	        btn.Size = UDim2.new(0, 80, 1, 0)
	        btn.Text = "Tab " .. tabCounter
	        btn.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
	        btn.TextColor3 = Color3.new(1, 1, 1)
	        btn.BorderSizePixel = 0
	        
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
	        tabObj.CodeFrame = cf
	        table.insert(tabs, tabObj)
	        
	        btn.MouseButton1Click:Connect(function()
	            switchTab(tabObj)
	        end)
	        
	        closeBtn.MouseButton1Click:Connect(function()
	            if #tabs <= 1 then return end
	            cf.Frame:Destroy()
	            btn:Destroy()
	            
	            for i, v in ipairs(tabs) do
	                if v == tabObj then
	                    table.remove(tabs, i)
	                    break
	                end
	            end
	            
	            if activeTab == tabObj then
	                switchTab(tabs[#tabs])
	            end
	            
	            local totalWidth = 0
	            for _, v in ipairs(tabs) do
	                totalWidth = totalWidth + v.Button.AbsoluteSize.X
	            end
	            tabBar.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
	        end)
	        
	        local totalWidth = 0
	        for _, v in ipairs(tabs) do
	            totalWidth = totalWidth + v.Button.AbsoluteSize.X
	        end
	        tabBar.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
	        
	        switchTab(tabObj)
	    end
	
	    addTabBtn.MouseButton1Click:Connect(createTab)
	    createTab()
	
	    local copy = Instance.new("TextButton", window.GuiElems.Content)
	    copy.BackgroundTransparency = 1
	    copy.Size = UDim2.new(0.25, 0, 0, 20)
	    copy.Position = UDim2.new(0, 0, 1, -20)
	    copy.Text = "Copy"
	    copy.TextColor3 = Color3.new(1, 1, 1)
	
	    copy.MouseButton1Click:Connect(function()
	        if activeTab then
	            local source = activeTab.CodeFrame:GetText()
	            env.setclipboard(source)
	        end
	    end)
	
	    local save = Instance.new("TextButton", window.GuiElems.Content)
	    save.BackgroundTransparency = 1
	    save.Size = UDim2.new(0.25, 0, 0, 20)
	    save.Position = UDim2.new(0.25, 0, 1, -20)
	    save.Text = "Save"
	    save.TextColor3 = Color3.new(1, 1, 1)
	
	    save.MouseButton1Click:Connect(function()
	        if activeTab then
	            local source = activeTab.CodeFrame:GetText()
	            local filename = "dex/saved/Notepad_" .. os.date("%Y%m%d_%H%M%S") .. ".lua"
	            env.writefile(filename, source)
	            if env.movefileas then
	                env.movefileas(filename, ".lua")
	            end
	        end
	    end)
	
	    local execute = Instance.new("TextButton", window.GuiElems.Content)
	    execute.BackgroundTransparency = 1
	    execute.Size = UDim2.new(0.25, 0, 0, 20)
	    execute.Position = UDim2.new(0.5, 0, 1, -20)
	    execute.Text = "Execute"
	    execute.TextColor3 = Color3.new(1, 1, 1)
	
	    if env.loadstring then
	        execute.TextColor3 = Color3.new(1, 1, 1)
	        execute.Interactable = true
	    else
	        execute.TextColor3 = Color3.new(0.5, 0.5, 0.5)
	        execute.Interactable = false
	    end
	
	    execute.MouseButton1Click:Connect(function()
	        if activeTab then
	            local source = activeTab.CodeFrame:GetText()
	            env.loadstring(source)()
	        end
	    end)
	
	    local clear = Instance.new("TextButton", window.GuiElems.Content)
	    clear.BackgroundTransparency = 1
	    clear.Size = UDim2.new(0.25, 0, 0, 20)
	    clear.Position = UDim2.new(0.75, 0, 1, -20)
	    clear.Text = "Clear"
	    clear.TextColor3 = Color3.new(1, 1, 1)
	
	    clear.MouseButton1Click:Connect(function()
	        if activeTab then
	            activeTab.CodeFrame:SetText("")
	        end
	    end)
	end

	return Notepad
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}