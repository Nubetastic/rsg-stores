fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rsg-stores'
version '2.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/configShops.lua',
}

client_scripts {
    'client/hours.lua',
    'client/client.lua',
}

server_scripts {
    'server/webhook.lua',
    'server/server.lua',
    'server/versionchecker.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
    'ox_target',
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/script.js',
    'locales/*.json'
}

lua54 'yes'
