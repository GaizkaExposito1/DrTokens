fx_version 'cerulean'
game 'gta5'

author 'DrHub'
description 'Sistema avanzado de tokens con comandos de consola y webhooks Discord'
version '2.1.0'

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