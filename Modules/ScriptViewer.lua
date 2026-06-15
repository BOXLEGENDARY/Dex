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
			if PreviousScr ~= nil then
				pcall(function()
					local getgc = env.getgc
					local getupvalues = env.getupvalues
					local getconstants = env.getconstants
					local getinfo = env.getinfo
					
					local original_header = ("\n-- // Script Path: %s\n\n--[["):format(PreviousScr:GetFullName())
					local dump_buffer = {}
					local functions, function_count, data_base = {}, 0, {}
					
					function functions:add_to_dump(str, indentation, new_line)
						if new_line == nil then new_line = true end
						table.insert(dump_buffer, ("%s%s%s"):format(string.rep("\t\t", indentation), tostring(str), new_line and "\n" or ""))
					end
					
					function functions:get_function_name(func)
						local n = getinfo(func).name
						return (n and n ~= "") and n or "Unknown Name"
					end
					
					function functions:dump_table(input, indent, index)
						local indent = indent < 0 and 0 or indent
						functions:add_to_dump(("%s [%s] = %s"):format(tostring(index), typeof(input), tostring(input)), indent - 1)
						local count = 0
						for index, value in pairs(input) do
							count = count + 1
							if type(value) == "function" then
								functions:add_to_dump(("%d [function] = %s"):format(count, functions:get_function_name(value)), indent)
							elseif type(value) == "table" then
								if not data_base[value] then
									data_base[value] = true
									functions:add_to_dump(("%d [table]:"):format(count), indent)
									functions:dump_table(value, indent + 1, index)
								else
									functions:add_to_dump(("%d [table] (Recursive table detected)"):format(count), indent)
								end
							else
								functions:add_to_dump(("%d [%s] = %s"):format(count, typeof(value), tostring(value)), indent)
							end
						end
					end
					
					function functions:dump_function(input, indent)
						local func_name = functions:get_function_name(input)
						functions:add_to_dump(("\nFunction Dump: %s"):format(func_name), indent)
						
						functions:add_to_dump(("\nFunction Upvalues: %s"):format(func_name), indent)
						for index, upvalue in pairs(getupvalues(input)) do
							if type(upvalue) == "function" then
								functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(upvalue)), indent + 1)
							elseif type(upvalue) == "table" then
								if not data_base[upvalue] then
									data_base[upvalue] = true
									functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
									functions:dump_table(upvalue, indent + 2, index)
								else
									functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
								end
							else
								functions:add_to_dump(("%d [%s] = %s"):format(index, typeof(upvalue), tostring(upvalue)), indent + 1)
							end
						end
						
						functions:add_to_dump(("\nFunction Constants: %s"):format(func_name), indent)
						for index, constant in pairs(getconstants(input)) do
							if type(constant) == "function" then
								functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(constant)), indent + 1)
							elseif type(constant) == "table" then
								if not data_base[constant] then
									data_base[constant] = true
									functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
									functions:dump_table(constant, indent + 2, index)
								else
									functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
								end
							else
								functions:add_to_dump(("%d [%s] = %s"):format(index, typeof(constant), tostring(constant)), indent + 1)
							end
						end
					end
					
					for _, _function in pairs(getgc()) do
						if typeof(_function) == "function" and getfenv(_function).script and getfenv(_function).script == PreviousScr then
							functions:dump_function(_function, 0)
							functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
						end
					end
					
					local source = codeFrame:GetText()
					if #dump_buffer > 0 then 
						source = source .. original_header .. table.concat(dump_buffer) .. "]]" 
					end
					codeFrame:SetText(source)
				end)
			end
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