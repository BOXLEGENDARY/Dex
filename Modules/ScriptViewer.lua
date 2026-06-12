--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
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
	Notebook = Apps.Notebook
end

local function main()
	local ScriptViewer = {}
	local window, codeFrame
	local PreviousScr = nil
	
	ScriptViewer.ViewScript = function(scr)
		local success, source, time = pcall(env.decompile or function() end, scr)
		if not success or not source then source, PreviousScr = "-- DEX - Source failed to decompile", nil else PreviousScr = scr end
		if time then source = "-- Decompiler in: " .. tostring(time) .. "s\n" .. source end
		codeFrame:SetText(source:gsub("\0", "\\0"))
		window:Show()
	end

	ScriptViewer.DisassembleScript = function(scr)
		local success, source = pcall(env.disassemble or function() end, scr)
		if not success or not source then 
			source = "-- DEX - Source failed to disassemble\n-- " .. tostring(source)
			PreviousScr = nil 
		else 
			PreviousScr = scr 
		end
		codeFrame:SetText(source:gsub("\0", "\\0"))
		window:Show()
	end

	ScriptViewer.Init = function()
	    window = Lib.Window.new()
	    window:SetTitle("Scriptviewer")
	    window:Resize(500, 400)
	    ScriptViewer.Window = window
	    
	    codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,20)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-20)
	    codeFrame.Frame.Parent = window.GuiElems.Content
	    
		local copyBtn = Instance.new("TextButton", window.GuiElems.Content)
		copyBtn.BackgroundTransparency = 1
		copyBtn.Size = UDim2.new(0.25, 0, 0, 20)
		copyBtn.Position = UDim2.new(0, 0, 0, 0)
		copyBtn.Text = "Copy"
		copyBtn.TextColor3 = Color3.new(1, 1, 1)
		
		copyBtn.MouseButton1Click:Connect(function()
		    if env.setclipboard then
		        env.setclipboard(codeFrame:GetText())
		    end
		end)
		
		local saveBtn = Instance.new("TextButton", window.GuiElems.Content)
		saveBtn.BackgroundTransparency = 1
		saveBtn.Size = UDim2.new(0.25, 0, 0, 20)
		saveBtn.Position = UDim2.new(0.25, 0, 0, 0)
		saveBtn.Text = "Save"
		saveBtn.TextColor3 = Color3.new(1, 1, 1)
		
		saveBtn.MouseButton1Click:Connect(function()
		    if env.writefile then
		        local scriptName = PreviousScr and PreviousScr.Name or "Decompiled"
		        local filename = "dex/saved/" .. scriptName .. "_" .. os.date("%H%M%S") .. ".lua"
		        env.writefile(filename, codeFrame:GetText())
		    end
		end)
		
		local dumpBtn = Instance.new("TextButton", window.GuiElems.Content)
		dumpBtn.BackgroundTransparency = 1
		dumpBtn.Size = UDim2.new(0.25, 0, 0, 20)
		dumpBtn.Position = UDim2.new(0.50, 0, 0, 0)
		dumpBtn.Text = "Dump Functions"
		dumpBtn.TextColor3 = Color3.new(1, 1, 1)
	    
	    dumpBtn.MouseButton1Click:Connect(function()
	        if PreviousScr == nil then return end
	    
	        pcall(function()
	            local getgc = env.getgc
	            local getupvalues = env.getupvalues
	            local getconstants = env.getconstants
	            local getinfo = env.getinfo
	            local getfenv = getfenv
	    
	            local dump_buffer = {
	                ("\n-- Function Dumper \n-- Target: %s\n\n--[["):format(PreviousScr:GetFullName())
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
	                        add_to(label .. " (Circular Reference)", indent)
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

		local toNotepadBtn = Instance.new("TextButton", window.GuiElems.Content)
		toNotepadBtn.BackgroundTransparency = 1
		toNotepadBtn.Size = UDim2.new(0.25, 0, 0, 20)
		toNotepadBtn.Position = UDim2.new(0.75, 0, 0, 0)
		toNotepadBtn.Text = "To Notepad"
		toNotepadBtn.TextColor3 = Color3.new(1, 1, 1)
		
		toNotepadBtn.MouseButton1Click:Connect(function()
		    local source = codeFrame:GetText()
		    local scriptName = PreviousScr and PreviousScr.Name or "Decompiled"
		    
		    if Apps.Notepad and Apps.Notepad.OpenInTab then
		        Apps.Notepad.OpenInTab(source, scriptName .. ".lua", nil)
		    end
		end)
	end

	return ScriptViewer
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}