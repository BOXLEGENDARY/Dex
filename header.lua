--[[ Developed by ZxL ]]



if _G.LOADED then return end
_G.LOADED = true

local selection
local nodes = {}
local env = {}

local oldgame = game
local game = workspace.Parent

local _registry_table = nil
local _marker = Instance.new("Folder")

local function _find_instance_registry()
    local reg = env.getreg
    local k, v = next(reg)
    while k ~= nil do
        if type(v) == "table" and rawget(v, "__mode") == "kvs" then
            for _, obj in next, v do
                if obj == _marker then
                    return v
                end
            end
        end
        k, v = next(reg, k)
    end
    return nil
end

cloneref = function(instance)
    if type(instance) ~= "userdata" then return instance end

    if not _registry_table then
        _registry_table = _find_instance_registry()
    end

    if _registry_table then
        for k, v in next, _registry_table do
            if v == instance then
                _registry_table[k] = nil
                break
            end
        end
    end

    return instance
end