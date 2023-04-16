fx_version 'cerulean'
game 'gta5'

ui_page('ui/index.html')

author 'Doğukan Duran (goodluck)'
description 'Contextmenu for FiveM'
version '1.0.0'

client_scripts {
    '@PolyZone/client.lua',
	'@PolyZone/BoxZone.lua',
	'@PolyZone/EntityZone.lua',
	'@PolyZone/CircleZone.lua',
	'@PolyZone/ComboZone.lua',
    'Config.lua',
    'Client/*.lua',
}

server_scripts {
    'Config.lua',
    'Server/*.lua',
}

files {
	'ui/index.html',
    'ui/style.css',
    'ui/assets/*.png',
    'ui/main.js'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'

dependency 'PolyZone'
