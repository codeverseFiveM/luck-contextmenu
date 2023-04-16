Config = {
    -- Debug mode (will print object detials and create line for cursor and cam position)
    Debug = false,
    Standalone = false,
    DrawOutline = true,
    OutlineColor = {40, 237, 250, 255},
    DrawColor = {255, 255, 255, 150},
    SuccessDrawColor = {40, 237, 250, 255},
    ErrorDrawColor = {255, 0, 0, 255},
    DrawDistance = 15.0,
    DrawSprite = true,
    EnableDefaultOptions = true,
    EnableMouseRotate = false,
    MaxDistance = 7.0,
    DefaultDistance = 2,
    OpenConditons = function()
        return true
    end,
    KeyMappingSettings = {
        Label = "Open Context Menu",
        -- If you want to use a keybind, use the following format: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
        Key = "LMENU",
    },
    SelfOptions = {},
    Globals = {
        ObjectOptions = {},
        VehicleOptions = {},
        PlayerOptions = {},
        PedOptions = {},
    },
    CircleZones = {},
    BoxZones = {
        ["VehicleRental"] = {
            name = "vehiclerental",
            coords = vector3(109.9739, -1088.61, 28.302),
            length = 0.95,
            width = 0.9,
            heading = 345.64,
            debugPoly = false,
            minZ = 27.302,
            maxZ = 30.302, 
            options = {
                {
                  type = "client",
                  event = "qb-rental:openMenu",
                  icon = "fas fa-car",
                  label = "Araç Kiralama",
                },
            },
            distance = 3.5
        },
    },
    PolyZones = {},
    TargetBones = {},
    TargetModels = {
        ["bike"] = {
            models = {
                `bmx`,
                `cruiser`,
                `scorcher`,
                `fixter`,
                `tribike`,
                `tribike2`,
                `tribike3`,
            },
            options = {
                {
                    type = "event",
                    event = "pickup:bike",
                    icon = "fas fa-bicycle",
                    label = "Bisikleti Al",
                },
            },
            distance = 3.0
        },
    },
    Peds = {}
}


