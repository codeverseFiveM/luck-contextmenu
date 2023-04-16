Bones = {Options = {}, Vehicle = {'chassis', 'windscreen', 'seat_pside_r', 'seat_dside_r', 'bodyshell', 'suspension_lm', 'suspension_lr', 'platelight', 'attach_female', 'attach_male', 'bonnet', 'boot', 'chassis_dummy', 'chassis_Control', 'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r', 'Gun_GripR', 'windscreen_f', 'platelight', 'VFX_Emitter', 'window_lf', 'window_lr', 'window_rf', 'window_rr', 'engine', 'gun_ammo', 'ROPE_ATTATCH', 'wheel_lf', 'wheel_lr', 'wheel_rf', 'wheel_rr', 'exhaust', 'overheat', 'seat_dside_f', 'seat_pside_f', 'Gun_Nuzzle', 'seat_r'}}

if Config.EnableDefaultOptions then
    local BackEngineVehicles = {
        [`ninef`] = true,
        [`adder`] = true,
        [`vagner`] = true,
        [`t20`] = true,
        [`infernus`] = true,
        [`zentorno`] = true,
        [`reaper`] = true,
        [`comet2`] = true,
        [`comet3`] = true,
        [`jester`] = true,
        [`jester2`] = true,
        [`cheetah`] = true,
        [`cheetah2`] = true,
        [`prototipo`] = true,
        [`turismor`] = true,
        [`pfister811`] = true,
        [`ardent`] = true,
        [`nero`] = true,
        [`nero2`] = true,
        [`tempesta`] = true,
        [`vacca`] = true,
        [`bullet`] = true,
        [`osiris`] = true,
        [`entityxf`] = true,
        [`turismo2`] = true,
        [`fmj`] = true,
        [`re7b`] = true,
        [`tyrus`] = true,
        [`italigtb`] = true,
        [`penetrator`] = true,
        [`monroe`] = true,
        [`ninef2`] = true,
        [`stingergt`] = true,
        [`surfer`] = true,
        [`surfer2`] = true,
        [`gp1`] = true,
        [`autarch`] = true,
        [`tyrant`] = true
    }

    local function ToggleDoor(vehicle, door)
        if GetVehicleDoorLockStatus(vehicle) < 2 then
            if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
                SetVehicleDoorShut(vehicle, door, false)
            else
                SetVehicleDoorOpen(vehicle, door, false)
            end
        end
    end

    local FrontDoorOptions = {
        ["Toggle Front Door"] = {
            icon = "fas fa-door-open",
            labels = {
                {
                    label = "Open Front Door",
                    condition = function(entity)
                        return GetVehicleDoorAngleRatio(entity, 0) <= 0.0
                    end
                },
                {
                    label = "Close Front Door"
                }
            },
            canInteract = function(entity)
                return GetEntityBoneIndexByName(entity, 'door_dside_f') ~= -1 and GetVehicleDoorLockStatus(entity) < 2
            end,
            action = function(entity)
                ToggleDoor(entity, 0)
            end,
            distance = 1.8
        }
    }

    local BackDoorOptions = {
        ["Toggle Rear Door"] = {
            icon = "fas fa-door-open",
            labels = {
                {
                    label = "Open Back Door",
                    condition = function(entity)
                        return GetVehicleDoorAngleRatio(entity, 2) <= 0.0
                    end
                },
                {
                    label = "Close Back Door"
                }
            },
            canInteract = function(entity)
                return GetEntityBoneIndexByName(entity, 'door_dside_r') ~= -1 and GetVehicleDoorLockStatus(entity) < 2
            end,
            action = function(entity)
                ToggleDoor(entity, 2)
            end,
            distance = 1.8
        }
    }

    local HoodOptions = {
        ["Toggle Hood"] = {
            icon = "fa-solid fa-wrench",
            labels = {
                {
                    label = "Open Hood",
                    condition = function(entity)
                        return GetVehicleDoorAngleRatio(entity, BackEngineVehicles[GetEntityModel(entity)] and 5 or 4) <= 0.0
                    end
                },
                {
                    label = "Close Hood",
                }
            },
            action = function(entity)
                ToggleDoor(entity, BackEngineVehicles[GetEntityModel(entity)] and 5 or 4) 
            end,
            distance = 1.8
        }
    }

    local TrunkOptions = {
        ["Toggle Trunk"] = {
            icon = "fas fa-truck-ramp-box",
            labels = {
                {
                    label = "Open Trunk",
                    condition = function(entity)
                        return GetVehicleDoorAngleRatio(entity, BackEngineVehicles[GetEntityModel(entity)] and 4 or 5) <= 0.0
                    end
                },
                {
                    label = "Close Trunk",
                }
            },
            action = function(entity)
                ToggleDoor(entity, BackEngineVehicles[GetEntityModel(entity)] and 4 or 5)
            end,
            distance = 1.2
        },
    }


    Bones.Options['seat_dside_f'] = FrontDoorOptions
    Bones.Options['seat_pside_f'] = FrontDoorOptions

    Bones.Options['seat_dside_r'] = BackDoorOptions
    Bones.Options['seat_pside_r'] = BackDoorOptions

    Bones.Options['bonnet'] = HoodOptions
    Bones.Options['boot'] = TrunkOptions
end

return Bones