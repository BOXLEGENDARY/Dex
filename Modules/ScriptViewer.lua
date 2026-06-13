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
	    
	        local oldText = dumpBtn.Text
	        dumpBtn.Text = "Dumping..."
	        
	        task.spawn(function()
	            local success, result = pcall(function()
	                local getgc = env.getgc or getgc
	                local getupvalues = env.getupvalues or debug.getupvalues
	                local getconstants = env.getconstants or debug.getconstants
	                local getinfo = env.getinfo or debug.getinfo
	                local getfenv = getfenv
	        
	                local dump_buffer = {
	                    ("\n\n--[[ DUMP OUTPUT ]]\n-- Function Dumper \n-- Target: %s\n-- Dumped at: %s\n"):format(PreviousScr:GetFullName(), os.date("%X"))
	                }
	                local data_base = {}
	        
	                local function add_to(str, indent)
	                    table.insert(dump_buffer, string.rep("    ", indent or 0) .. tostring(str))
	                end
	        
	                local function get_func_details(f)
	                    local info = getinfo(f)
	                    local name = (info.name and info.name ~= "") and info.name or "Anonymous"
	                    local what = info.what or "Lua"
	                    local args = {}
	                    
	                    if info.numparams then
	                        for i = 1, info.numparams do table.insert(args, "p"..i) end
	                        if info.is_vararg then table.insert(args, "...") end
	                    end
	                    
	                    return ("%s(%s) %s"):format(name, table.concat(args, ", "), (what == "C") and "-- [C]" or "")
	                end
	        
	                local function format_val(val, v_type)
	                    if v_type == "string" then
	                        return '"' .. val:gsub("\n", "\\n"):gsub("\r", "\\r"):gsub('"', '\\"') .. '"'
	                    elseif v_type == "Instance" then
	                        local name = "nil"
	                        pcall(function() name = val:GetFullName() end)
	                        return name
	                    elseif v_type == "function" then
	                        return get_func_details(val)
	                    else
	                        return tostring(val)
	                    end
	                end
	        
	                local function process_value(val, name, indent)
	                    local indent_str = string.rep("    ", indent)
	                    local v_type = typeof(val)
	                    local key_str = type(name) == "string" and ('["%s"]'):format(name) or ("[%s]"):format(tostring(name))
	                    
	                    if v_type == "table" then
	                        if data_base[val] then
	                            add_to(indent_str .. key_str .. " = {}, -- <Circular Reference>", 0)
	                        else
	                            data_base[val] = true
	                            add_to(indent_str .. key_str .. " = {", 0)
	                            
	                            for k, v in pairs(val) do
	                                process_value(v, k, indent + 1)
	                            end
	                            
	                            local mt = getmetatable(val)
	                            if mt and type(mt) == "table" then
	                                add_to(indent_str .. "    -- <Metatable>", 0)
	                                for k, v in pairs(mt) do
	                                    process_value(v, k, indent + 1)
	                                end
	                            end
	                            add_to(indent_str .. "},", 0)
	                        end
	                    else
	                        add_to(indent_str .. key_str .. " = " .. format_val(val, v_type) .. ", -- <" .. v_type .. ">", 0)
	                    end
	                end
	        
	                local count = 0
	                for _, obj in pairs(getgc()) do
	                    if type(obj) == "function" then
	                        local s, fenv = pcall(getfenv, obj)
	                        if s and fenv and fenv.script == PreviousScr then
	                            add_to(string.rep("-", 50), 0)
	                            add_to("-- Function: " .. get_func_details(obj), 0)
	                            add_to(string.rep("-", 50), 0)
	                            
	                            local upvalues = getupvalues and getupvalues(obj) or {}
	                            if next(upvalues) then
	                                add_to("local Upvalues = {", 0)
	                                for i, v in pairs(upvalues) do
	                                    process_value(v, i, 1)
	                                end
	                                add_to("}\n", 0)
	                            end
	                            
	                            local constants = getconstants and getconstants(obj) or {}
	                            if next(constants) then
	                                add_to("local Constants = {", 0)
	                                for i, v in pairs(constants) do
	                                    process_value(v, i, 1)
	                                end
	                                add_to("}\n", 0)
	                            end
	                            
	                            count = count + 1
	                            if count % 15 == 0 then task.wait() end
	                        end
	                    end
	                end
	        
	                if count == 0 then
	                    add_to("-- No functions found belonging to this script in GC.", 0)
	                end
	                
	                table.insert(dump_buffer, "--[[ END OF DUMP ]]")
	                return table.concat(dump_buffer, "\n")
	            end)
	            
	            dumpBtn.Text = oldText
	            
	            if success then
	                codeFrame:SetText(codeFrame:GetText() .. "\n" .. result)
	            else
	                warn("Dump Error: " .. tostring(result))
	                codeFrame:SetText(codeFrame:GetText() .. "\n\n-- Dump Error: " .. tostring(result))
	            end
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