fx_version 'cerulean'
game 'gta5'

author 'Tacman'
version '0.1'
name 'TimeDisplay'
description 'A kind of "psuedo" wheel for spinning, in the casino (WIP)'
lua54 'no'

shared_scripts {
}

client_scripts {
    'client.lua',
    'config.lua',
}

server_scripts {
    'server.lua',
    'config.lua',
}

files {
    'sounds/wheelspin.mp3'
}

data_file 'AUDIO_WAVEPACK' 'sounds'