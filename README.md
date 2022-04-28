<p align="center">
<img src="https://raw.githubusercontent.com/fivemland/fl_dashboard/master/ui/src/assets/logo.png " width="100" height="100">
</p>

## FiveM Land Punishments - fl_punishment

### Dependencies

- [oxmysql](https://github.com/overextended/oxmysql 'oxmysql')
- [esx-legacy](https://github.com/esx-framework/esx-legacy 'esx-legacy')

### Commands

#### Admin

- /punishments - Open Admin panel with all punishments
- /comserv [Target Player] [Count] [Reason] - Putting a player in community service
- /removecomserv [TargetPlayer] - Remove player from community service
- /ban [Target Player] [Days (0 - Infinity)] [Reason] - Ban player
- /unban [Identifier / Character Name] - Revoke player ban
- /adminjail [Target Player] [Minutes] [Reason] - Putting a player to jail
- /unjail [Target Player] - Remove player from adminjail

### Exports

#### Server

```lua
-- name: comserv or jail
-- returns: table
getPlayerPunishment(xPlayer, name)
```

### Screenshots

[![1](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/1.png '1')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/1.png '1')

[![2](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/2.png '2')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/2.png '2')

[![3](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/3.png '3')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/3.png '3')

[![4](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/4.png '4')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/4.png '4')

[![5](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/5.png '5')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/5.png '5')

[![6](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/6.png '6')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/6.png '6')

[![7](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/7.png '7')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/7.png '7')[![8](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/8.png '8')](https://raw.githubusercontent.com/fivemland/fl_punishment/main/screenshots/8.png '8')
