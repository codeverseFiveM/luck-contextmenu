# luck-contextmenu
#### qb-target killer, but heavily inspired from qb-target
#### This script created by goodluck, one of the Codeverse developers.

## About this script
luck-contextmenu is for interaction with entities, players, PolyZones (PolyZone is required for this scripts), vehicles and etc.
You can add options for this things and player can be right click to added things for access options.
And you can add submenus for this things!

#### Information
You can start script without change any qb-target export!

## Features

- Submenu options, you can add infinite submenus!
- Options can have submenu and event on same time!
- Condition label (You can change options label with condition without create any other options.)
- Self clickable!
- Fast actions. (This script comes with default options named "Fast Actions", player can create fast actions for animations and commands!)
- Sprites for zones.
- Realtime check options. (Example you right click to player and one option requires police job. If your job change this option appear/disappear with animation from menu.)
- And other features from qb-target!
- canInteract option for check any condtions you typed!
- Global options for entites, vehicle bones, vehicles, players, peds and self interactions.

## Usage (Player)

1. Hold left alt key to show cursor.
2. Bring cursor to any thing with interactable options. (If thing have any options you can show eye image at corsor's top left.)
3. Right click to access thing's menu.
4. Now you can take your hand from left alt key.
5. Click to any option for interact.
5.1. If option has right arrow icon at right, on left click you will access submenu of option.
5.2. If option has menu icon at right, on left click you will trigger option's event. On right click you will access to option's submenu.
5.3 If option not has any icon at right on left click you will trigger option's event.

## Documanation for scripting

#### New features.

##### Priority
You can add priority for options, if you want at top of menu options you should give smallest number of menu.

### Both right, left clickable example.
```
{
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
}
```

##### Submenus example.
```
  ['Kıyafetler']= {
            label = 'Kıyafetler',
            icon = 'fa-solid fa-shirt',
            priority = -1,
            subOptions = {
                {
                    id = 'meer',
                    label = 'Accessoires',
                    icon = 'plus',
                    subOptions = {
                        {
                            id = 'Hat',
                            label = 'Hat',
                            icon = 'fa-solid fa-hat-cowboy',
                            type = 'client',
                            event = 'qb-radialmenu:ToggleProps',
                        }
                },
                {
                    id = 'Hair',
                    label = 'Hair',
                    icon = 'fa-solid fa-ribbon',
                    type = 'client',
                    event = 'qb-radialmenu:ToggleClothing',
                }
            }
        }, 
    },
```
##### Condation labels example.

```
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
```
