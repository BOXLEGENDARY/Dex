--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Console, SaveInstance, SettingsWindow, Notebook -- Major Apps
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
	ModelViewer = Apps.ModelViewer
	Console = Apps.Console
	SaveInstance = Apps.SaveInstance
	SettingsWindow = Apps.SettingsWindow
	Notebook = Apps.Notebook
end

local function main()
	local ScriptViewer = {}
	local window, codeFrame
	local PreviousScr = nil
	
	ScriptViewer.ViewScript = function(scr)
		local success, source, time = pcall(decompile or function() end, scr)
		if not success or not source then source, PreviousScr = "-- DEX - Source failed to decompile", nil else PreviousScr = scr end
		if time then source = "-- Decompiler in: " .. tostring(time) .. "s\n" .. source end
		codeFrame:SetText(source:gsub("\0", "\\0"))
		window:Show()
	end

	ScriptViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Notepad")
		window:Resize(500, 400)
		ScriptViewer.Window = window
		
		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,20)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-20)
		codeFrame.Frame.Parent = window.GuiElems.Content
		
		local copy = Instance.new("TextButton", window.GuiElems.Content)
		copy.BackgroundTransparency = 1
		copy.Size = UDim2.new(0.5,0,0,20)
		copy.Text = "Copy to Clipboard"
		copy.TextColor3 = Color3.new(1,1,1)

		copy.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.setclipboard(source)
		end)

		local save = Instance.new("TextButton",window.GuiElems.Content)
		save.BackgroundTransparency = 1
		save.Position = UDim2.new(0.35,0,0,0)
		save.Size = UDim2.new(0.3,0,0,20)
		save.Text = "Save to File"
		save.TextColor3 = Color3.new(1,1,1)
		
		save.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			local filename = "Place_"..game.PlaceId.."_Script_"..os.time()..".txt"

			env.writefile(filename, source)
			if env.movefileas then
				env.movefileas(filename, ".txt")
			end
		end)
		
        local execute = Instance.new("TextButton", window.GuiElems.Content)
		execute.BackgroundTransparency = 1
		execute.Size = UDim2.new(0.5,0,0,20)
		execute.Position = UDim2.new(0,0,1,-20)
		execute.Text = "Execute"
		execute.TextColor3 = Color3.new(1,1,1)
		
		if env.loadstring then
			execute.TextColor3 = Color3.new(1,1,1)
			execute.Interactable = true
		else
			execute.TextColor3 = Color3.new(0.5,0.5,0.5)
			execute.Interactable = false
		end

		execute.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.loadstring(source)()
		end)


		local clear = Instance.new("TextButton", window.GuiElems.Content)
		clear.BackgroundTransparency = 1
		clear.Size = UDim2.new(0.5,0,0,20)
		clear.Position = UDim2.new(0.5,0,1,-20)
		clear.Text = "Clear"
		clear.TextColor3 = Color3.new(1,1,1)

		clear.MouseButton1Click:Connect(function()
			codeFrame:SetText("")
		end)
		
		local dumpbtn = Instance.new("TextButton",window.GuiElems.Content)
		dumpbtn.BackgroundTransparency = 1
		dumpbtn.Position = UDim2.new(0.7,0,0,0)
		dumpbtn.Size = UDim2.new(0.3,0,0,20)
		dumpbtn.Text = "Dump Functions"
		dumpbtn.TextColor3 = Color3.new(1,1,1)
		
		dumpbtn.MouseButton1Click:Connect(function()
		    if PreviousScr == nil then return end
		
		    pcall(function()
		        local getgc, getupvalues = env.getgc, env.getupvalues
		        local getconstants, getinfo = env.getconstants, env.getinfo
		        local getfenv = getfenv
		
		        local dump_buffer = {
		            ("\n-- // Function Dumper \n-- // Target: %s\n\n--[["):format(PreviousScr:GetFullName())
		        }
		        local data_base = {}
		
		        local function add_to(str, indent)
		            table.insert(dump_buffer, string.rep("    ", indent or 0) .. tostring(str))
		        end
		
		        local function get_func_details(f)
		            local info = getinfo(f)
		            local name = (info.name ~= "" and info.name) or "Anonymous"
		            local what = info.what or "Lua"
		            local type_label = (what == "C") and " [C]" or ""
		            return ("%s%s"):format(name, type_label)
		        end
		
				local function process_value(val, name, indent)
				    local v_type = typeof(val)
				    local label = ("[%s] %s"):format(tostring(name), v_type)
				
				    if v_type == "function" then
				        add_to(label .. " = " .. get_func_details(val), indent)
				    elseif v_type == "table" then
				        if data_base[val] then
				            add_to(label .. " (Circular Reference / Already Dumped)", indent)
				        else
				            data_base[val] = true
				            add_to(label .. ":", indent)
				            
				            for k, v in pairs(val) do
				                process_value(v, k, indent + 1)
				            end
				            
				            local mt = getmetatable(val)
				            if mt then
				                add_to("[Metatable]:", indent + 1)
				                for k, v in pairs(mt) do
				                    local m_v_type = typeof(v)
				                    if m_v_type == "function" then
				                        add_to(("[%s] function = %s"):format(tostring(k), get_func_details(v)), indent + 2)
				                    elseif m_v_type == "table" then
				                        add_to(("[%s] table (Sub-table)"):format(tostring(k)), indent + 2)
				                    else
				                        add_to(("[%s] %s = %s"):format(tostring(k), m_v_type, tostring(v)), indent + 2)
				                    end
				                end
				            end
				        end
				    elseif v_type == "Instance" then
				        add_to(label .. " = " .. (val.ClassName == "DataModel" and "game" or val:GetFullName()), indent)
				    elseif v_type == "string" then
				        add_to(label .. ' = "' .. val .. '"', indent)
				    else
				        add_to(label .. " = " .. tostring(val), indent)
				    end
				end
		
		        for _, obj in pairs(getgc()) do
		            if type(obj) == "function" and getfenv(obj).script == PreviousScr then
		                add_to("\nFUNCTION: " .. get_func_details(obj), 0)
		                
		                add_to("[Upvalues]", 1)
		                for i, v in pairs(getupvalues(obj)) do
		                    process_value(v, i, 2)
		                end
		
		                add_to("[Constants]", 1)
		                for i, v in pairs(getconstants(obj)) do
		                    process_value(v, i, 2)
		                end
		                
		                add_to(string.rep("-", 50), 0)
		            end
		        end
		
		        table.insert(dump_buffer, "]]")
		        codeFrame:SetText(codeFrame:GetText() .. table.concat(dump_buffer, "\n"))
		    end)
		end)
	 end

	return ScriptViewer
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}