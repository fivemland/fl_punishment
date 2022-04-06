fx_version("cerulean")
game("gta5")
author("Csoki")

dependency("es_extended")
dependency("oxmysql")

shared_script("@es_extended/imports.lua")
server_script("@oxmysql/lib/MySQL.lua")

shared_script("shared.lua")

server_script("server.lua")
client_script("client.lua")

files({
	"ui/*",
})

-- ui_page("ui/index.html")
ui_page("http://localhost:3000")
