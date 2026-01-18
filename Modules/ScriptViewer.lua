--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]

-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, ModelViewer, Console, SaveInstance, Notebook -- Major Apps
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
	Notebook = Apps.Notebook
end

local function main()
	local ScriptViewer = {}
	local window, codeFrame
	local PreviousScr = nil
	
	ScriptViewer.ViewScript = function(scr)
		local success, source, time = pcall(decompile or env.decompile or function() end, scr)
		if not success or not source then source, PreviousScr = "-- DEX - Source failed to decompile", nil else PreviousScr = scr end
		if time then source = "-- Decompiled in: " .. tostring(time) .. "s\n" .. source end
		codeFrame:SetText(source:gsub("\0", "\\0"))
		window:Show()
	end

	ScriptViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Script Viewer")
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
		
		local dumpbtn = Instance.new("TextButton",window.GuiElems.Content)
		dumpbtn.BackgroundTransparency = 1
		dumpbtn.Position = UDim2.new(0.7,0,0,0)
		dumpbtn.Size = UDim2.new(0.3,0,0,20)
		dumpbtn.Text = "Dump Functions"
		dumpbtn.TextColor3 = Color3.new(1,1,1)
		
		dumpbtn.MouseButton1Click:Connect(function()
			if PreviousScr ~= nil then
				pcall(function()
					local getgc = env.getgc
					local getupvalues = env.getupvalues
					local getconstants = env.getconstants
					local getinfo = env.getinfo
					local original = ("\n-- // Function Dumper \n-- // Script Path: %s\n\n--[["):format(PreviousScr:GetFullName())
					local dump = original
					local functions, function_count, data_base = {}, 0, {}
		
					function functions:add_to_dump(str, indentation, new_line)
						local new_line = (new_line == nil) and true or new_line
						dump = dump .. (string.rep("    ", indentation or 0) .. tostring(str) .. (new_line and "\n" or ""))
					end
		
					function functions:get_function_name(func)
						local name = getinfo(func).name or ""
						return name ~= "" and name or "UnknownName"
					end
		
					function functions:dump_table(input, indent, index, depth)
						depth = depth or 0
						indent = (indent or 0) < 0 and 0 or (indent or 0)
		
						functions:add_to_dump(("[%s] [%s]: %s"):format(tostring(index or "?"), typeof(input), tostring(input)), math.max((indent or 0) - 1, 0))
						local count = 0
						for k, v in pairs(input) do
							count = count + 1
							if type(v) == "function" then
								functions:add_to_dump(("[%d] [function] = %s"):format(count, functions:get_function_name(v)), indent)
							elseif type(v) == "table" then
								if not data_base[v] then
									data_base[v] = true
									functions:add_to_dump(("[%d] [table]:"):format(count), indent)
									functions:dump_table(v, indent + 1, k, depth + 1)
								else
									functions:add_to_dump(("[%d] [table] (Recursive table detected)"):format(count), indent)
								end
							else
								functions:add_to_dump(("[%d] [%s] = %s"):format(count, tostring(typeof(v)), tostring(v)), indent)
							end
						end
						-- dump metatable
						local mt = getmetatable(input)
						if mt and not data_base[mt] then
							data_base[mt] = true
							functions:add_to_dump(string.rep("  ", indent) .. "[Metatable]:", indent)
							functions:dump_table(mt, indent + 1, "metatable", depth + 1)
						end
					end
		
					function functions:dump_function(input, indent)
						indent = indent or 0
						functions:add_to_dump(("\nFunction Dump: %s"):format(functions:get_function_name(input)), indent)
		
						-- Dump upvalues
						functions:add_to_dump("\nFunction Upvalues:", indent)
						for index, upvalue in pairs(getupvalues(input)) do
							if type(upvalue) == "function" then
								functions:add_to_dump(("[%d] [function] = %s"):format(index, functions:get_function_name(upvalue)), indent + 1)
							elseif type(upvalue) == "table" then
								if not data_base[upvalue] then
									data_base[upvalue] = true
									functions:add_to_dump(("[%d] [table]:"):format(index), indent + 1)
									functions:dump_table(upvalue, indent + 2, index)
								else
									functions:add_to_dump(("[%d] [table] (Recursive table detected)"):format(index), indent + 1)
								end
							else
								functions:add_to_dump(("[%d] [%s] = %s"):format(index, tostring(typeof(upvalue)), tostring(upvalue)), indent + 1)
							end
						end
		
						-- Dump constants
						functions:add_to_dump("\nFunction Constants:", indent)
						for index, constant in pairs(getconstants(input)) do
							if type(constant) == "function" then
								functions:add_to_dump(("[%d] [function] = %s"):format(index, functions:get_function_name(constant)), indent + 1)
							elseif type(constant) == "table" then
								if not data_base[constant] then
									data_base[constant] = true
									functions:add_to_dump(("[%d] [table]:"):format(index), indent + 1)
									functions:dump_table(constant, indent + 2, index)
								else
									functions:add_to_dump(("[%d] [table] (Recursive table detected)"):format(index), indent + 1)
								end
							else
								functions:add_to_dump(("[%d] [%s] = %s"):format(index, tostring(typeof(constant)), tostring(constant)), indent + 1)
							end
						end
					end
		
					-- Iterate all functions in getgc
					for _, _function in pairs(getgc()) do
						if typeof(_function) == "function" and getfenv(_function).script == PreviousScr then
							functions:dump_function(_function, 0)
							functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
						end
					end
		
					local source = codeFrame:GetText()
					if dump ~= original then
						source = source .. dump .. "]]"
					end
					codeFrame:SetText(source)
				end)
			end
		end)
	 end

	return ScriptViewer
end

return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}