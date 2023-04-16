-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- Heavily inspired by QB-Target

local function JobCheck() return true end
local function GangCheck() return true end
local function JobTypeCheck() return true end
local function ItemCheck() return true end
local function CitizenCheck() return true end


CreateThread(function()
	local state = GetResourceState('qb-core')
	if state ~= 'missing' then
		local timeout = 0
		while state ~= 'started' and timeout <= 100 do
			timeout = timeout + 1
			state = GetResourceState('qb-core')
			Wait(0)
		end
		Config.Standalone = false
	end
	if Config.Standalone then
		local firstSpawn = false
		local event = AddEventHandler('playerSpawned', function()
			SpawnPeds()
			firstSpawn = true
		end)
		-- Remove event after it has been triggered
		while true do
			if firstSpawn then
				RemoveEventHandler(event)
				break
			end
			Wait(1000)
		end
	else
		local QBCore = exports['qb-core']:GetCoreObject()
		local PlayerData = QBCore.Functions.GetPlayerData()

		AddFastActionToMetadata = function(type)
			local PlayerData = QBCore.Functions.GetPlayerData()
			local fastactions = PlayerData.metadata["fastactions"] or {animations = {}, commands = {}}
			local headerName = type == "animations" and "animation" or "command"
			local action = exports['qb-input']:ShowInput({
				header = "Add new " .. headerName,
				submitText = "Add",
				inputs = {
					{
						type = 'text',
						name = 'label',
						text = "Title"
					},
					{
						type = 'text',
						isRequired = true,
						name = 'action',
						text = type == "animations" and "Animation (sit)" or "Command (seat)"
					}
				}
			})

			if fastactions[type] == nil then
				fastactions[type] = {}
			end
		
			if action then
				table.insert(fastactions[type], {
					label = #action.label > 0 and action.label or action.action,
					action = action.action,
				})
			end
		
			TriggerServerEvent('luck-contextmenu:server:SetFastActions', fastactions)
			
			AddFastActions(fastactions["animations"], fastactions["commands"])
		end
		
		AddFastActions = function(animations, commands)
			animations = animations or {}
			commands = commands or {}

			-- If animations more than 10, player can't add new animations
			local animationSubOptions = #animations < 10 and {{
				label = "Add Animation",
				icon = "fa-solid fa-circle-plus",
				action = function()
					AddFastActionToMetadata("animations")
				end,
			}} or {}
		
			local commandSubOptions = #commands < 10 and {{
				label = "Add Command",
				icon = "fa-solid fa-circle-plus",
				action = function()
					AddFastActionToMetadata("commands")
				end,
			}} or {}
		
			if animations then
				for _, v in pairs(animations) do
					table.insert(animationSubOptions, {
						label = v.label,
						event = "e " .. v.action,
						icon = "fa-solid fa-face-smile",
						type = "animation",
						subOptions = {
							{
								label = "Remove Animation",
								icon = "fa-solid fa-trash",
								action = function()
									for i = 1, #animations do
										if animations[i].action == v.action then
											table.remove(animations, i)
											break
										end
									end

									TriggerServerEvent('luck-contextmenu:SetFastActions', animations, "animations")

									AddFastActions(animations, commands)
								end
							}
						}
					})
				end
			end
		
			if commands then
				for _, v in pairs(commands) do
					table.insert(commandSubOptions, {
						label = v.label,
						event = v.action,
						icon = "fa-solid fa-bolt",
						type = "command",
						subOptions = {
							{
								label = "Remove Command",
								icon = "fa-solid fa-trash",
								action = function()
									for i = 1, #commands do
										if commands[i].action == v.action then
											table.remove(commands, i)
											break
										end
									end

									TriggerServerEvent('luck-contextmenu:SetFastActions', commands, "commands")

									AddFastActions(animations, commands)
								end
							}
						}
					})
				end
			end
		
			AddSelfOption({
				label = "Animations",
				icon = "fa-solid fa-face-smile",
				subOptions = animationSubOptions,
				priority = 4,
			})
		
			AddSelfOption({
				label = "Commands",
				icon = "fa-solid fa-bolt",
				subOptions = commandSubOptions,
				priority = 5,
			})
		end

		ItemCheck = QBCore.Functions.HasItem

		if PlayerData and PlayerData.metadata and PlayerData.metadata["fastactions"] and Config.EnableDefaultOptions then
			AddFastActions(PlayerData.metadata["fastactions"]["animations"], PlayerData.metadata["fastactions"]["commands"])
		end

		JobCheck = function(job)
			if type(job) == 'table' then
				job = job[PlayerData.job.name]
				if job and PlayerData.job.grade.level >= job then
					return true
				end
			elseif job == 'all' or job == PlayerData.job.name then
				return true
			end
			return false
		end

		JobTypeCheck = function(jobType)
			if type(jobType) == 'table' then
				jobType = jobType[PlayerData.job.type]
				if jobType then
					return true
				end
			elseif jobType == 'all' or jobType == PlayerData.job.type then
				return true
			end
			return false
		end

		GangCheck = function(gang)
			if type(gang) == 'table' then
				gang = gang[PlayerData.gang.name]
				if gang and PlayerData.gang.grade.level >= gang then
					return true
				end
			elseif gang == 'all' or gang == PlayerData.gang.name then
				return true
			end
			return false
		end

		CitizenCheck = function(citizenid)
			return citizenid == PlayerData.citizenid or citizenid[PlayerData.citizenid]
		end

		RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
			PlayerData = QBCore.Functions.GetPlayerData()

			if PlayerData and PlayerData.metadata and PlayerData.metadata["fastactions"] and Config.EnableDefaultOptions then
				AddFastActions(PlayerData.metadata["fastactions"]["animations"], PlayerData.metadata["fastactions"]["commands"])
			end
		end)

		RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
			PlayerData = {}
			DeletePeds()
		end)

		RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
			PlayerData.job = JobInfo
		end)

		RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
			PlayerData.gang = GangInfo
		end)

		RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
			PlayerData = val

			if PlayerData and PlayerData.metadata and PlayerData.metadata["fastactions"] and Config.EnableDefaultOptions then
				AddFastActions(PlayerData.metadata["fastactions"]["animations"], PlayerData.metadata["fastactions"]["commands"])
			end
		end)
	end
end)

function CheckOption(data, entity)
	data.distance = data.distance or Config.DefaultDistance

	if entity.distance and data.distance and entity.distance > data.distance then return false end
	if data.job and not JobCheck(data.job) then return false end
	if data.excludejob and JobCheck(data.excludejob) then return false end
	if data.jobType and not JobTypeCheck(data.jobType) then return false end
	if data.excludejobType and JobTypeCheck(data.excludejobType) then return false end
	if data.gang and not GangCheck(data.gang) then return false end
	if data.excludegang and GangCheck(data.excludegang) then return false end
	if data.item and not ItemCheck(data.item) then return false end
	if data.citizenid and not CitizenCheck(data.citizenid) then return false end
	if data.canInteract and not data.canInteract(entity.target, distance, data) then return false end
	return true
end
