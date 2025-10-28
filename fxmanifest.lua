fx_version 'cerulean'
game 'gta5'

author 'DrHub'
description 'Sistema de tokens por tiempo para QBCore'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/discord.lua',
    'server/server.lua'
}

client_scripts {
    'client/client.lua'
}

lua54 'yes'