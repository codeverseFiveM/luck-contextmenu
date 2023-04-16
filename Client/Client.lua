local display = false;
local isMenuOpen = false;
local flag = 30;
local currentEntity = {
    target = -1,
    type = -1,
    hash = -1,
    closestBone = -1,
    endCoords = vector3(0, 0, 0),
    maxDistance = -1,
    distance = -1,
    options = {},
    isPlayer = false,
    isZone = false,
};

local successZone = false;
local isTriedForSprites = false;

local menuEntity = currentEntity;

local Zones = {}

local Globals = {
    PlayerOptions = Config.Globals.PlayerOptions,
    ObjectOptions = Config.Globals.ObjectOptions,
    VehicleOptions = Config.Globals.VehicleOptions,
    PedOptions = Config.Globals.PedOptions,
}

local SelfOptions = Config.SelfOptions;
local VehicleOptions = {};
local Models = {};
local Entities = {};
local Players = {};
local Vehicles = {};
local Bones = Bones or {};
local controlIsEnabled = false;

local Sprites = {}

-- Draw sprites on screen
function DrawSpirtes()
	CreateThread(function()
		while not HasStreamedTextureDictLoaded("shared") do Wait(10) RequestStreamedTextureDict("shared", true) end
		local sleep
		local colorCodes = {
            r,
            g,
            b,
            a
        }

		while display do
			sleep = 500
			for _, zone in pairs(Sprites) do
				sleep = 0
                for i, code in pairs(colorCodes) do
                    code = zone.targetOptions.drawColor?[i] or Config.DrawColor[i]
                end

				if zone.success and #currentEntity.options > 0 then
                    for i, code in pairs(colorCodes) do
                        code = zone.targetOptions.successDrawColor?[i] or Config.SuccessDrawColor[i]
                    end
                elseif zone.success and #currentEntity.options == 0 then
                    for i, code in pairs(colorCodes) do
                        code = zone.targetOptions.errorDrawColor?[i] or Config.ErrorDrawColor[i]
                    end
				end

				SetDrawOrigin(zone.center.x, zone.center.y, zone.center.z, 0)
				DrawSprite("shared", "info_icon_32", 0, 0, 0.015, 0.025, 0, colorCodes[1], colorCodes[2], colorCodes[3], colorCodes[4])
				ClearDrawOrigin()
			end
			Wait(sleep)
		end
		Sprites = {}
	end)
end

-- Keymapping for opening the context menu

RegisterKeyMapping("+cmenu", Config.KeyMappingSettings.Label, "keyboard", Config.KeyMappingSettings.Key);

RegisterCommand("+cmenu", function()
    SetDisplay();
end, false);

RegisterCommand("-cmenu", function()
    if not isMenuOpen then
        SetDisplay(false);
    end
end, false);

-- NUI Callbacks

RegisterNUICallback("SET_MENU_STATE", function(data, cb)
    isMenuOpen = data.state;
    if not isMenuOpen then
        SetDisplay(false);
    else
        menuEntity = currentEntity;
    end
end)

RegisterNUICallback("OPTION_SELECTED", function(data, cb)
    OptionSelected(data.index);
    cb("ok");
end)

RegisterNUICallback("REFRESH_CURRENT_ENTITY_OPTIONS", function(data, cb)
    SendOptions(currentEntity.options);
    menuEntity = currentEntity;
    cb("ok");
end)

-- NUI Messages

function SendOptions(options)
    SendNUIMessage({
        action = "SET_OPTIONS",
        options = RemoveAllFunctionsFromOptions(options),
    });
end

function CloseNUIContextMenu()
    SendNUIMessage({
        action = "CLOSE_CONTEXT_MENU",
    });

    isMenuOpen = false;
end

function ChangeItemState(index, state)
    SendNUIMessage({
        action = "CHANGE_ITEM_STATE",
        index = index,
        state = state,
    });
end

-- Functions

function OptionSelected(optionIndex)
    local option = GetOptionByIndex(optionIndex);

    if option then
        if option.action then
            option.action(option.entity)
        elseif option.event then
			if option.type == "client" then
				TriggerEvent(option.event, option)
			elseif option.type == "server" then
				TriggerServerEvent(option.event, option)
			elseif option.type == "command" then
				ExecuteCommand(option.event)
			elseif option.type == "qbcommand" then
				TriggerServerEvent('QBCore:CallCommand', option.event, option)
			else
				TriggerEvent(option.event, option)
			end
        end
    end
end

function RefreshCurrentEntityAndSend()
    DrawOutlineEntity(currentEntity.target, false)

    currentEntity = {
        target = -1,
        type = 0,
        hash = 0,
        closestBone = 0,
        endCoords = currentEntity.endCoords,
        distance = 0,
        options = {},
        isPlayer = false,
    };

    if not isMenuOpen then
        menuEntity = currentEntity;
    end

    SendOptions(currentEntity.options);
end

function SetDisplay(bool)
    if not Config.OpenConditons() then return end

    isTriedForSprites = false;

    if bool ~= nil then
        display = bool;
    else
        display = not display;
    end

    SetNuiFocus(display, display);
    SetNuiFocusKeepInput(display);
    SetCursorLocation(0.5, 0.5);

    if not display then
        DrawOutlineEntity(currentEntity.target, false)
        RefreshCurrentEntityAndSend();
        CloseNUIContextMenu();
    else
        if Config.DrawSprite then
            DrawSpirtes();
        end
    end
end

function GetOptionByIndex(index, options)
    options = options or menuEntity.options;

    local optionIndexs = type(index) == "string" and Split(index, ".") or {index};
    for _ = 1, #optionIndexs do
        optionIndexs[_] = tonumber(optionIndexs[_]);
    end
    if #optionIndexs > 1 then
        local deletedOption =  table.remove(optionIndexs, 1);

        local optionIndexString = table.concat(optionIndexs, ".");
        return GetOptionByIndex(optionIndexString, options[deletedOption].subOptions);
    else 
        return options[tonumber(optionIndexs[1])];
    end
    return option;
end

function RemoveAllFunctionsFromOptions(options)
    local newOptions = {};
    for _, option in pairs(options) do
        local newOption = {};
        for key, value in pairs(option) do
            if type(value) ~= "function" and key ~= "labels" then
                newOption[key] = value;
            end
            
            if key == "subOptions" then
                newOption[key] = RemoveAllFunctionsFromOptions(value);
            end
        end
        table.insert(newOptions, newOption);
    end
    return newOptions;
end


function GetOptions(entity) 
    local options = {};

    local isAnyVisible = false;
    
    local coords = GetEntityCoords(PlayerPedId());

    if entity.target == PlayerPedId() then
        for _, option in pairs(SelfOptions) do
            table.insert(options, option);
        end
    end

    if Models[entity.hash] then
        for _, option in pairs(Models[entity.hash]) do
             table.insert(options, option);
        end
    end

    if Entities[entity.target] then
        for _, option in pairs(Entities[entity.target]) do
            table.insert(options, option);
        end

        if GlobalObjectOptions then
            for _, option in pairs(GlobalObjectOptions) do
                table.insert(options, option);
            end
        end
    end

    if NetworkGetEntityIsNetworked(entity.target) then
        local netId = NetworkGetNetworkIdFromEntity(entity.target);
        if Entities[netId] then
            for _, option in pairs(Entities[netId]) do
                table.insert(options, option);
            end
        end

   
        if Globals.ObjectOptions then
            for _, option in pairs(Globals.ObjectOptions) do
                table.insert(options, option);
            end
        end
    end

    if entity.type == 1 then
        if IsPedAPlayer(entity.target) and entity.target ~= PlayerPedId() then
            if Globals.PlayerOptions then
                for _, option in pairs(Globals.PlayerOptions) do
                    table.insert(options, option);
                end
            end
        else
            if Globals.PedOptions then
                for _, option in pairs(Globals.PedOptions) do
                    table.insert(options, option);
                end
            end
        end
    elseif entity.type == 2 then
        local closestBone, _, closestBoneName = CheckBones(entity.endCoords, entity.target, Bones.Vehicle)
        local datatable = Bones.Options[closestBoneName];

        if datatable and closestBone then
            for _, option in pairs(datatable) do
                table.insert(options, option);
            end
        end

        if Globals.VehicleOptions then
            for _, option in pairs(Globals.VehicleOptions) do
                table.insert(options, option);
            end
        end
    end

    for k, zone in pairs(Zones) do
        if Config.DrawSprite then
            if #(currentEntity.endCoords - zone.center) < (zone.targetOptions.drawDistance or Config.DrawDistance) then
                Sprites[k] = zone
            else
                Sprites[k] = nil
            end
        end

        if entity.distance < (Config.MaxDistance) and entity.distance <= zone.targetOptions.distance and zone:isPointInside(currentEntity.endCoords) then
            entity.maxDistance = zone.targetOptions.distance;
            local zOptions = zone.targetOptions.options;
            if #zOptions > 0 then
                for _, option in pairs(zOptions) do
                    table.insert(options, option);
                end

                Sprites[k].success = true;
                entity.isZone = true;
                successZone = k;
            end
        end
    end


    function AddIndexAndCheckOptions(options, currentEntity, index)
        for _, option in pairs(options) do
            option.index = index and index .. "." .. _ or _;
            option.entity = currentEntity.target;
            if CheckOption(option, currentEntity) then
                option.display = true;

                if option.labels and next(option.labels) ~= nil then
                    local isLabelFound = false;
                    for labelKey, label in pairs(option.labels) do
                        if label.condition and label.condition(currentEntity.target) then
                            option.label = label.label;
                            isLabelFound = true;
                            break;
                        end

                        if not isLabelFound and #option.labels == labelKey then
                            option.label = label.label
                        end
                    end
                end

                if option.action or option.event then
                    option.isAction = true;
                end

                if option.subOptions then
                    option.subOptions = AddIndexAndCheckOptions(option.subOptions, currentEntity, option.index);
                end
                isAnyVisible = true;
            else
                option.display = false;
            end
        end
        return options;
    end

    return AddIndexAndCheckOptions(options, entity), isAnyVisible;
end

Citizen.CreateThread(function()
    while true do
        local run = true;

        if not display then
            Citizen.Wait(200);
        end

        if not display and controlIsEnabled then
            run = false;
        end

        if run then
            DisableControlAction(0, 142, display); -- MeleeAttackAlternate
            DisableControlAction(0, 24, display);  -- Attack
            DisableControlAction(0, 25, display);  -- Aim
            DisableControlAction(0, 47, display);  -- Weapon
            DisableControlAction(0, 199, display); -- PauseMenu
            DisableControlAction(0, 200, display); -- ESC

            -- Disable mouse
            if not Config.EnableMouseRotate then
                DisableControlAction(0, 1, display); -- LookLeftRight
                DisableControlAction(0, 2, display); -- LookUpDown
                DisableControlAction(0, 106, display); -- VehicleMouseControlOverride
            end

            if not display then
                controlIsEnabled = true;
            end
        end

        Citizen.Wait(0);
    end
end)

Citizen.CreateThread(function()
    while true do
        -- Check distance of opened menu's option
        local ped = PlayerPedId();
        if display and menuEntity.target ~= -1 and menuEntity.target ~= ped then
            menuEntity.distance = #(menuEntity.endCoords - GetEntityCoords(ped));

            if menuEntity.maxDistance and menuEntity.distance > menuEntity.maxDistance then
                RefreshCurrentEntityAndSend();
                CloseNUIContextMenu();
            end

            isAnyVisible = false;

            function CheckOptions(options)
                for _, option in pairs(options) do
                    local checkOption = CheckOption(option, menuEntity)
                    if checkOption and not option.display then
                        option.display = true;
                        ChangeItemState(option.index, true);
                    elseif not checkOption and option.display then
                        ChangeItemState(option.index, false);
                        option.display = false;
                    end
                    if option.subOptions then
                        CheckOptions(option.subOptions);
                    end

                    if option.display then
                        isAnyVisible = true;
                    end
                end
            end
            CheckOptions(menuEntity.options);

            if not isAnyVisible then
                RefreshCurrentEntityAndSend();
                CloseNUIContextMenu();
            end
        else
            Citizen.Wait(1000);
        end

        Citizen.Wait(300)
    end
end)

-- Main Thread

Citizen.CreateThread(function()
    local flag = -1;
    local isSuccess
    local isRaycastSuccess = false;
    while true do
        Citizen.Wait(0);
        if display then
            local ped = PlayerPedId();
            local pedCoords = GetEntityCoords(ped);

            flag = not isRaycastSuccess and flag == -1 and 30 or -1;

            local hit, entityHit, entityType, direction, distance, endCoords = RaycastCursor(flag);

            entityHit = entityHit or 0;
            entityType = entityType or 0;


            if hit then
                isRaycastSuccess = true;
            else
                isRaycastSuccess = false;
            end

            -- Check if the entity is the same as the last one
            if entityHit == currentEntity.target and ((distance - currentEntity.distance) < 1 or currentEntity.target == ped) and not Config.Debug then
                Citizen.Wait(100);
            else 
                DrawOutlineEntity(currentEntity.target, false);

                flag = 30;
                local hash = entityType > 0 and GetEntityModel(entityHit) or 0;

                local entity = {
                    target = entityHit,
                    type = entityType,
                    hash = hash,
                    endCoords = endCoords,
                    distance = distance,
                    isPlayer = false,
                };

                if entityType == 1 then
                    local player = GetPlayerFromServerId(entityHit);
                    if player ~= -1 then
                        entity.isPlayer = true;
                    end
                end

                currentEntity = entity;

                local options, isAnyVisible = GetOptions(entity);

                if #options > 0 and isAnyVisible then
                    isSuccess = true;
                    if not currentEntity.isZone then
                        DrawOutlineEntity(currentEntity.target, true);
                    end
                    currentEntity.options = options;
                    SendOptions(options);
                else
                    RefreshCurrentEntityAndSend();
                    if not Config.Debug then
                        Citizen.Wait(100);
                    end

                    if successZone then
                        if Sprites[successZone] then
                            Sprites[successZone].success = false;
                        end

                        successZone = false;
                    end

                    isSuccess = false;
                end
            end

            -- Debug
            if Config.Debug then
                if hit == 0 then
                    entityType = 0;
                end

                local entityName = GetEntityName(entityType) or "Unknown";

                print("Entity Hit: " .. entityHit);
                print("Entity Type: " .. entityType);
                print("Entity Name: " .. entityName);
                print("Entity Distance: " .. distance);
                if entity then
                    print("Entity Hash: " .. entity.hash);
                    print("Entity Options: " .. #entity.options);
                end
    
                DrawLine(pedCoords, direction, hit == 1 and 0 or 255, hit == 1 and 255 or 0, 0, 255);
            end
        else
            Citizen.Wait(150);
        end
    end
end)

function CheckBones(coords, entity, bonelist)
	local closestBone = -1
	local closestDistance = 20
	local closestPos, closestBoneName
	for _, v in pairs(bonelist) do
		if Bones.Options[v] then
			local boneId = GetEntityBoneIndexByName(entity, v)
			local bonePos = GetWorldPositionOfEntityBone(entity, boneId)
			local distance = #(coords - bonePos)
			if closestBone == -1 or distance < closestDistance then
				closestBone, closestDistance, closestPos, closestBoneName = boneId, distance, bonePos, v
			end
		end
	end
	if closestBone ~= -1 then return closestBone, closestPos, closestBoneName
	else return false end
end

function AddSelfOption(option)
    SelfOptions[option.label] = option
end

local function SetOptions(table, distance, options)
	for _, v in pairs(options) do
		if v.required_item then
			v.item = v.required_item
			v.required_item = nil
		end
		if not v.distance or v.distance > distance then v.distance = distance end
		table[v.label] = v
	end
end

local function AddGlobalObject(options)
    options.distance = options.distance or Config.MaxDistance
    SetOptions(Globals.ObjectOptions, options.distance, options.options)
end

local function AddGlobalPed(options)
    options.distance = options.distance or Config.MaxDistance
    SetOptions(Globals.PedOptions, options.distance, options.options)
end

local function AddGlobalVehicle(options)
    options.distance = options.distance or Config.MaxDistance
    SetOptions(Globals.VehicleOptions, options.distance, options.options)
end

local function AddGlobalPlayer(options)
    options.distance = options.distance or Config.MaxDistance
    SetOptions(Globals.PlayerOptions, options.distance, options.options)
end

local function AddCircleZone(name, center, radius, zoneOptions, options)
	local centerType = type(center)
	center = (centerType == 'table' or centerType == 'vector4') and vec3(center.x, center.y, center.z) or center
	Zones[name] = CircleZone:Create(center, radius, zoneOptions)
	options.distance = options.distance or Config.MaxDistance
	Zones[name].targetOptions = options
	return Zones[name]
end

local function AddBoxZone(name, center, length, width, zoneOptions, options)
	local centerType = type(center)
	center = (centerType == 'table' or centerType == 'vector4') and vec3(center.x, center.y, center.z) or center
	Zones[name] = BoxZone:Create(center, length, width, zoneOptions)
	options.distance = options.distance or Config.MaxDistance
	Zones[name].targetOptions = options
	return Zones[name]
end

local function AddPolyZone(name, points, zoneOptions, options)
	local _points = {}
	local pointsType = type(points[1])
	if pointsType == 'table' or pointsType == 'vector3' or pointsType == 'vector4' then
		for i = 1, #points do
			_points[i] = vec2(points[i].x, points[i].y)
		end
	end
	Zones[name] = PolyZone:Create(#_points > 0 and _points or points, zoneOptions)
	options.distance = options.distance or Config.MaxDistance
	Zones[name].targetOptions = options
	return Zones[name]
end

local function AddComboZone(zones, zoneOptions, options)
	Zones[options.name] = ComboZone:Create(zones, zoneOptions)
	options.distance = options.distance or Config.MaxDistance
	Zones[options.name].targetOptions = options
	return Zones[options.name]
end

local function AddEntityZone(name, entity, zoneOptions, options)
	Zones[name] = EntityZone:Create(entity, zoneOptions)
	options.distance = options.distance or Config.MaxDistance
	Zones[name].targetOptions = options
	return Zones[name]
end

local function RemoveZone(name)
	if not Zones[name] then return end
	if Zones[name].destroy then Zones[name]:destroy() end
	Zones[name] = nil
end

local function AddTargetBone(bones, parameters)
    bones = type(bones) == 'table' and bones or {bones}
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options

    for _, bone in pairs(bones) do
        if not Bones.Options[bone] then Bones.Options[bone] = {} end
        SetOptions(Bones.Options[bone], distance, options)
    end
end

local function RemoveTargetBone(bones, labels)
    bones = type(bones) == 'table' and bones or {bones}
    for _, bone in pairs(bones) do
        if labels then
            labels = type(labels) == 'table' and labels or {labels}
            for _, v in pairs(labels) do
                if Bones.Options[bone] then
                    Bones.Options[bone][v] = nil
                end
            end
        else
            Bones.Options[bone] = nil
        end
    end
end

local function AddTargetEntity(entities, parameters)
    entities = type(entities) == 'table' and entities or {entities}
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options

    for _, entity in pairs(entities) do
        if NetworkGetEntityIsNetworked(entity) then entity = NetworkGetNetworkIdFromEntity(entity) end -- Allow non-networked entities to be targeted
        if not Entities[entity] then Entities[entity] = {} end
        SetOptions(Entities[entity], distance, options)
    end
end

local function RemoveTargetEntity(entities, labels)
    entities = type(entities) == 'table' and entities or {entities}

    for _, entity in pairs(entities) do
        if NetworkGetEntityIsNetworked(entity) then entity = NetworkGetNetworkIdFromEntity(entity) end -- Allow non-networked entities to be targeted
        if labels then
            labels = type(labels) == 'table' and labels or {labels}
            for _, v in pairs(labels) do
                if Entities[entity] then
                    Entities[entity][v] = nil
                end
            end
        else
            Entities[entity] = nil
        end
    end
end

local function AddTargetModel(models, parameters)
    models = type(models) == 'table' and models or {models}
	local distance, options = parameters.distance or Config.MaxDistance, parameters.options

    for _, model in pairs(models) do
        if type(model) == 'string' then model = joaat(model) end
        if not Models[model] then Models[model] = {} end
        SetOptions(Models[model], distance, options)
    end
end

local function RemoveTargetModel(models, labels)
    models = type(models) == 'table' and models or {models}

    for _, model in pairs(models) do
        if type(model) == 'string' then model = joaat(model) end
        if labels then
            labels = type(labels) == 'table' and labels or {labels}
            for _, v in pairs(labels) do
                if Models[model] then
                    Models[model][v] = nil
                end
            end
        else
            Models[model] = nil
        end
    end
end

local function SpawnPed(data)
	local spawnedped
    local key, value = next(data)
	if type(value) ~= 'table' and type(key) == 'string' then
        data = {data}
    end
    
    for _, v in pairs(data) do
        if v.spawnNow then
            RequestModel(v.model)
            while not HasModelLoaded(v.model) do
                Wait(0)
            end

            if type(v.model) == 'string' then v.model = joaat(v.model) end

            if v.minusOne then
                spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w or 0.0, v.networked or false, true)
            else
                spawnedped = CreatePed(0, v.model, v.coords.x, v.coords.y, v.coords.z, v.coords.w or 0.0, v.networked or false, true)
            end

            if v.freeze then
                FreezeEntityPosition(spawnedped, true)
            end

            if v.invincible then
                SetEntityInvincible(spawnedped, true)
            end

            if v.blockevents then
                SetBlockingOfNonTemporaryEvents(spawnedped, true)
            end

            if v.animDict and v.anim then
                RequestAnimDict(v.animDict)
                while not HasAnimDictLoaded(v.animDict) do
                    Wait(0)
                end

                TaskPlayAnim(spawnedped, v.animDict, v.anim, 8.0, 0, -1, v.flag or 1, 0, false, false, false)
            end

            if v.scenario then
                SetPedCanPlayAmbientAnims(spawnedped, true)
                TaskStartScenarioInPlace(spawnedped, v.scenario, 0, true)
            end

            if v.pedrelations and type(v.pedrelations.groupname) == 'string' then
                if type(v.pedrelations.groupname) ~= 'string' then error(v.pedrelations.groupname .. ' is not a string') end

                local pedgrouphash = joaat(v.pedrelations.groupname)

                if not DoesRelationshipGroupExist(pedgrouphash) then
                    AddRelationshipGroup(v.pedrelations.groupname)
                end

                SetPedRelationshipGroupHash(spawnedped, pedgrouphash)
                if v.pedrelations.toplayer then
                    SetRelationshipBetweenGroups(v.pedrelations.toplayer, pedgrouphash, joaat('PLAYER'))
                end

                if v.pedrelations.toowngroup then
                    SetRelationshipBetweenGroups(v.pedrelations.toowngroup, pedgrouphash, pedgrouphash)
                end
            end

            if v.weapon then
                if type(v.weapon.name) == 'string' then v.weapon.name = joaat(v.weapon.name) end

                if IsWeaponValid(v.weapon.name) then
                    SetCanPedEquipWeapon(spawnedped, v.weapon.name, true)
                    GiveWeaponToPed(spawnedped, v.weapon.name, v.weapon.ammo, v.weapon.hidden or false, true)
                    SetPedCurrentWeaponVisible(spawnedped, not v.weapon.hidden or false, true)
                end
            end

            if v.target then
                if v.target.useModel then
                    AddTargetModel(v.model, {
                        options = v.target.options,
                        distance = v.target.distance
                    })
                else
                    AddTargetEntity(spawnedped, {
                        options = v.target.options,
                        distance = v.target.distance
                    })
                end
            end

            v.currentpednumber = spawnedped

            if v.action then
                v.action(v)
            end
        end

        local nextnumber = #Config.Peds + 1
        if nextnumber <= 0 then nextnumber = 1 end

        Config.Peds[nextnumber] = v
    end
end

Citizen.CreateThread(function()
    if table.type(Config.CircleZones) ~= 'empty' then
        for _, v in pairs(Config.CircleZones) do
            AddCircleZone(v.name, v.coords, v.radius, {
                name = v.name,
                debugPoly = v.debugPoly,
				useZ = v.useZ,
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if table.type(Config.BoxZones) ~= 'empty' then
        for _, v in pairs(Config.BoxZones) do
            AddBoxZone(v.name, v.coords, v.length, v.width, {
                name = v.name,
                heading = v.heading,
                debugPoly = v.debugPoly,
                minZ = v.minZ,
                maxZ = v.maxZ
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if table.type(Config.PolyZones) ~= 'empty' then
        for _, v in pairs(Config.PolyZones) do
            AddPolyZone(v.name, v.points, {
                name = v.name,
                debugPoly = v.debugPoly,
                minZ = v.minZ,
                maxZ = v.maxZ
            }, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if table.type(Config.TargetBones) ~= 'empty' then
        for _, v in pairs(Config.TargetBones) do
            AddTargetBone(v.bones, {
                options = v.options,
                distance = v.distance
            })
        end
    end

    if table.type(Config.TargetModels) ~= 'empty' then
        for _, v in pairs(Config.TargetModels) do
            AddTargetModel(v.models, {
                options = v.options,
                distance = v.distance
            })
        end
    end
end)

function IsDisplay()
    return display
end

exports('CheckBones', CheckBones)

exports("AddGlobalObject",  AddGlobalObject)
exports("AddGlobalPed",  AddGlobalPed)
exports("AddGlobalVehicle",  AddGlobalVehicle)
exports("AddGlobalPlayer", AddGlobalPlayer)

exports("AddTargetEntity", AddTargetEntity)
exports("AddTargetModel", AddTargetModel)
exports("AddTargetBone", AddTargetBone)
exports("AddCircleZone", AddCircleZone)
exports("AddBoxZone", AddBoxZone)
exports("AddPolyZone", AddPolyZone)
exports("AddComboZone", AddComboZone)
exports("AddEntityZone", AddEntityZone)

exports("RemoveTargetBone", RemoveTargetBone)
exports("RemoveTargetEntity", RemoveTargetEntity)
exports("RemoveTargetModel", RemoveTargetModel)
exports("RemoveZone", RemoveZone)

exports("SpawnPed", SpawnPed)

exports("IsDisplay", IsDisplay)

local contextExports = {
	["CheckBones"] = CheckBones,

	["AddGlobalObject"] = AddGlobalObject,
	["AddGlobalPed"] = AddGlobalPed,
	["AddGlobalVehicle"] = AddGlobalVehicle,
    ["AddGlobalPlayer"] = AddGlobalPlayer,

	["AddTargetEntity"] = AddTargetEntity,
	["AddTargetModel"] = AddTargetModel,
    ["AddTargetBone"] = AddTargetBone,
	["AddCircleZone"] = AddCircleZone,
	["AddBoxZone"] = AddBoxZone,
	["AddComboZone"] = AddComboZone,
	["AddEntityZone"] = AddEntityZone,
	["AddTargetModel"] = AddTargetModel,

	["RemoveTargetBone"] = RemoveTargetBone,
	["RemoveTargetEntity"] = RemoveTargetEntity,
	["RemoveTargetModel"] = RemoveTargetModel,
	["RemoveZone"] = RemoveZone,

    ["SpawnPed"] = SpawnPed,

    ["IsDisplay"] = IsDisplay
}

for exportName, func in pairs(contextExports) do
	AddEventHandler(('__cfx_export_qb-target_%s'):format(exportName), function(setCB)
		setCB(func)
	end)
end
