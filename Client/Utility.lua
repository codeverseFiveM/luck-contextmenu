--[[
    Utility.lua
    If you don't know what you're doing, don't touch this file.
]]--

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
end

function DrawOutlineEntity(entity, bool)
	if not Config.DrawOutline then return end
    if not DoesEntityExist(entity) then return end
    if IsEntityAPed(entity) then return end
    if IsEntityAVehicle(entity) then
        SetEntityDrawOutline(entity, false)
        return
    end
	SetEntityDrawOutline(entity, bool)
	SetEntityDrawOutlineColor(Config.OutlineColor[1], Config.OutlineColor[2], Config.OutlineColor[3], Config.OutlineColor[4])
    SetEntityDrawOutlineShader(1)
end

function Split(s, sep)
    local fields = {}
    
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
    
    return fields
end

function TableConcat(t1,t2)
    for _,v in ipairs(t2) do 
        table.insert(t1, v)
    end
    return t1
end

function GetEntityName(type)
    if type == 0 then
        return "None"
    elseif type == 1 then
        return "Ped"
    elseif type == 2 then
        return "Vehicle"
    elseif type == 3 then
        return "Object"
    end
end


local glm = require 'glm'

local flag = 30

local function ScreenPositionToCameraRay()
    local pos = GetFinalRenderedCamCoord()
    local rot = glm.rad(GetFinalRenderedCamRot(2))
    local q = glm.quatEulerAngleZYX(rot.z, rot.y, rot.x)
    local cursor = vector2(GetControlNormal(0, 239), GetControlNormal(0, 240))
    -- print(GetFinalRenderedCamCoord())
    return pos, glm.rayPicking(
        q * glm.forward(),
        q * glm.up(),
        glm.rad(GetFinalRenderedCamFov()),
        GetAspectRatio(true),
        0.10000, -- GetFinalRenderedCamNearClip(),
        10000.0, -- GetFinalRenderedCamFarClip(),
        cursor.x * 2.0 - 1.0, cursor.y * 2.0 - 1.0
    )
end

function RaycastCursor(flag)
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    local rayPos, rayDir = ScreenPositionToCameraRay()
	local direction = rayPos + 16 * rayDir
	local rayHandle = StartShapeTestLosProbe(rayPos.x, rayPos.y, rayPos.z, direction.x, direction.y, direction.z, flag or 30, 0, 4)

    local isSuccess = false
    while not isSuccess do
		local result, hit, endCoords, _, entityHit = GetShapeTestResult(rayHandle)

		if result ~= 1 then
            if entityHit >= 1 then
                entityType = GetEntityType(entityHit)
            end

            distance = #(pedCoords - endCoords)

            if entityType == 0 and pcall(GetEntityModel, entityHit) then
				entityType = 3
                isTypeZero = true
			end

            isSuccess = true

            return hit, entityHit, entityType, direction, distance, endCoords or cam3DPos
        end

        Citizen.Wait(0)
    end
end
