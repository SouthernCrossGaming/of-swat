# Open Fortress SWAT
Open Fortress rendition of the classic [SWAT](https://halo.fandom.com/wiki/Team_SWAT) gametype from the Halo series. 

Gameplay Changes:
- Players spawn with an assault rifle, revolver, and crowbar only.
- All weapons spawns and health pills are removed.
- Headshots are enabled.
- Damage falloff is disabled.
- Damage values are tweaked (based upon cvars)

## Compatible Games
- Open Fortress

## Supported Platforms
- Linux

## Installation
Download the [latest release](https://github.com/SouthernCrossGaming/of-swat/releases/latest/download/of-swat.zip), unzip and copy to your `open_fortress/addons/sourcemod` directory.

## Configuration

### Enabling/disabling the SWAT gametype
Enabling SWAT during an active round is safe to do. Disabling is not and will not replace entities that were removed or reset player loadouts.  
  
`of_swat_enabled` (0/1, default 0)  

### Configuring damage values
`of_swat_dmg_ar_headshot` - Sets damage for assault rifle headshots (default 50.0)  
`of_swat_dmg_ar_bodyshot` - Sets damage for assault rifle bodyshots (default 25.0)  
`of_swat_dmg_rev_headshot` - Sets damage for revolver headshots (default 150.0)  
`of_swat_dmg_rev_bodyshot` - Sets damage for revolver bodyshots (default 40.0)  
