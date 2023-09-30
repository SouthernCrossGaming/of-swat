# Open Fortress SWAT

<div align="center">
  An Open Fortress rendition of the classic <a href=https://halo.fandom.com/wiki/Team_SWAT>SWAT</a> gametype from the Halo series. 
  </br>
  </br>
  <img src="https://github.com/SouthernCrossGaming/of-swat/assets/20617130/050dd5dd-c6ef-4f62-b138-1b30e94211bf" width=512>
  </br>
  <sub>SFM Poster Credit:<a href=https://marlee-goat.neocities.org/> marlee_goat</a></sub>
</div>

---

### Gameplay Changes
- Players spawn with an assault rifle, revolver, and crowbar only.
- Assault rifle is moved to slot 3.
- All weapons spawns and health pills are disabled.
- Headshots for assult rifle and revolver are enabled.
- Damage falloff is disabled.
- Damage values are tweaked (based upon cvars).

## Compatible Games
- Open Fortress

## Supported Platforms
- Linux

## Installation
Download the [latest release](https://github.com/SouthernCrossGaming/of-swat/releases/latest/download/of-swat.zip), unzip and copy to your `open_fortress/addons/sourcemod` directory.

## Configuration

### Enabling/disabling the SWAT gametype
Enabling and disabling SWAT during an active round is safe to do. All weapons spawners and pills will be disabled when SWAT is enabled and will reappear when SWAT is disabled.  
  
`of_swat_enabled` - Enables or disables the SWAT gametype (0/1, default 0)  

### Configuring damage values
`of_swat_dmg_ar_headshot` - Sets damage for assault rifle headshots (default 50.0)  
`of_swat_dmg_ar_bodyshot` - Sets damage for assault rifle bodyshots (default 25.0)  
`of_swat_dmg_rev_headshot` - Sets damage for revolver headshots (default 150.0)  
`of_swat_dmg_rev_bodyshot` - Sets damage for revolver bodyshots (default 40.0)  

### Powerups
`of_powerups` - It is recommended to disable powerups for this gametype by setting this standard CVar to 0

# Credits
- [Fraeven](https://fraeven.dev) (Code, Testing)
- [Rowedahelicon](https://rowdythecrux.dev) (Debugging Assistance)
- [Greenie](https://steamcommunity.com/id/wannabemapper/) (Open Fortress Concept)
- [Bungie](https://en.wikipedia.org/wiki/Bungie) (Original Concept)
- [marlee_goat](https://marlee-goat.neocities.org/) (SFM Poster)
- Many members of the Open Fortress community (Testing)
