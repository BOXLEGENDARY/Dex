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
	                local getgc = env.getgc
	                local getupvalues = env.getupvalues
	                local getconstants = env.getconstants
	                local getinfo = env.getinfo
	                local getprotos = env.getprotos
	                local getfenv = getfenv
	        
	                local dump_buffer = {
	                    ("\n\n--[[ DUMP OUTPUT\n" ..
	                    "Target: %s\n" ..
	                    "Dumped at: %s\n")
	                    :format(PreviousScr:GetFullName(), os.date("%X"))
	                }
	        
	                local visited = {}
	                local loop_counter = 0
	        
	                local function add_to(str, indent)
	                    table.insert(dump_buffer, string.rep("    ", indent or 0) .. tostring(str))
	                end
	        
	                local function get_func_info(f)
	                    local ok, info = pcall(getinfo, f)
	                    if not ok or not info then
	                        return { name = "Anonymous", what = "Lua", source = "?", linedefined = -1, numparams = 0, is_vararg = false }
	                    end
	                    return {
	                        name = (info.name and info.name ~= "") and info.name or "Anonymous",
	                        what = info.what or "Lua",
	                        source = info.short_src or "?",
	                        linedefined = info.linedefined or -1,
	                        numparams = info.numparams or 0,
	                        is_vararg = info.is_vararg or false
	                    }
	                end
	        
	                local function format_val(val)
	                    local t = typeof(val)
	                    if t == "string" then
	                        return '"' .. val:gsub("\n","\\n"):gsub("\r","\\r"):gsub('"','\\"') .. '"'
	                    elseif t == "number" or t == "boolean" then
	                        return tostring(val)
	                    elseif t == "Instance" then
	                        local name = "nil"
	                        pcall(function() name = val:GetFullName() end)
	                        return name
	                    elseif t == "function" then
	                        local inf = get_func_info(val)
	                        return ("<function %s>"):format(inf.name)
	                    elseif t == "userdata" then
	                        return "<userdata>"
	                    elseif t == "thread" then
	                        return "<thread>"
	                    else
	                        return tostring(val)
	                    end
	                end
	        
	                local process_value
	                process_value = function(val, name, indent)
	                    loop_counter = loop_counter + 1
	                    if loop_counter % 5000 == 0 then task.wait() end
	                    
	                    local t = typeof(val)
	                    local key = type(name) == "string" and ('["%s"]'):format(name) or ("[%s]"):format(tostring(name))
	                    local tabs = string.rep("    ", indent)
	        
	                    if t == "table" then
	                        if visited[val] then
	                            add_to(tabs .. key .. " = <Circular Reference>,")
	                            return
	                        end
	                        visited[val] = true
	                        add_to(tabs .. key .. " = {")
	                        
	                        for k, v in pairs(val) do
	                            process_value(v, k, indent + 1)
	                        end
	                        
	                        local mt = getmetatable(val)
	                        if mt and type(mt) == "table" then
	                            add_to(tabs .. "    __metatable = {")
	                            for k, v in pairs(mt) do
	                                process_value(v, k, indent + 2)
	                            end
	                            add_to(tabs .. "    },")
	                        end
	                        add_to(tabs .. "},")
	                    else
	                        add_to(tabs .. key .. " = " .. format_val(val) .. ", -- <" .. t .. ">")
	                    end
	                end
	        
	                local count = 0
	                local gc_data = getgc()
	                for _, obj in pairs(gc_data) do
	                    loop_counter = loop_counter + 1
	                    if loop_counter % 5000 == 0 then task.wait() end
	                    
	                    if type(obj) == "function" then
	                        local ok, fenv = pcall(getfenv, obj)
	                        
	                        if ok and fenv and fenv.script == PreviousScr then
	                            local inf = get_func_info(obj)
	                            local func_address = tostring(obj)
	                            
	                            add_to("")
	                            add_to(string.rep("=", 50))
	                            add_to("Function : " .. inf.name)
	                            add_to("Address  : " .. func_address)
	                            add_to("Type     : " .. inf.what)
	                            add_to("Source   : " .. inf.source)
	                            add_to("Params   : " .. tostring(inf.numparams))
	                            add_to("VarArg   : " .. tostring(inf.is_vararg))
	                            add_to(string.rep("=", 50))
	        
	                            local upvalues = getupvalues and getupvalues(obj) or {}
	                            if next(upvalues) then
	                                add_to("")
	                                add_to("Upvalues = {")
	                                for k, v in pairs(upvalues) do
	                                    process_value(v, k, 1)
	                                end
	                                add_to("}")
	                            end
	        
	                            local constants = getconstants and getconstants(obj) or {}
	                            if next(constants) then
	                                add_to("")
	                                add_to("Constants = {")
	                                for k, v in pairs(constants) do
	                                    process_value(v, k, 1)
	                                end
	                                add_to("}")
	                            end
	        
	                            local protos = getprotos and getprotos(obj) or {}
	                            if #protos > 0 then
	                                add_to("")
	                                add_to("Prototypes = {")
	                                for i, p in ipairs(protos) do
	                                    local pinfo = get_func_info(p)
	                                    add_to(("[%d] = <function %s>,"):format(i, pinfo.name), 1)
	                                end
	                                add_to("}")
	                            end
	        
	                            count = count + 1
	                        end
	                    end
	                end
	        
	                if count == 0 then
	                    add_to("-- No functions found.")
	                end
	        
	                table.insert(dump_buffer, "]]")
	                return table.concat(dump_buffer, "\n")
	            end)
	            
	            dumpBtn.Text = oldText
	            
	            if success then
	                codeFrame:SetText(codeFrame:GetText() .. result)
	            else
	                warn("Dump Error: " .. tostring(result))
	                codeFrame:SetText(codeFrame:GetText() .. "\n\n--[[ Dump Error: \n" .. tostring(result) .. "\n]]")
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