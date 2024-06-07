Windowkill Autosplitter

Usage guide:
1. Get Livesplit from [their website](https://livesplit.org/)
2. Download [the latest release](https://github.com/kr1viah/WKAutosplitter/releases) of my autosplitter mod, make sure its the `kr1v-autosplitter-3.1.2` one
3. Put the contents of the zip `kr1v-autosplitter-3.1.2` in /Windowkill-install-path/

   Notes: For 3.0 you should probably have a new folder somewhere, and put the game in there. This makes organising a whole lot easier.
   You will need [modUtils](https://github.com/ombrellus/ModUtils/releases) as a mod too for this to work. Put the contents of this file in /Windowkill-install-path/mods/
   I tested the mod with version 3.1.2, so there are no guarantees every feature will work on 3.0.0
5. Open livesplit and right click -> control -> start TCP server
6. Launch the game
Repeat steps 5 and 6 everytime you want to use this mod in-game

Some things to note:
You can tweak the settings in game at settings -> speedrun
  
  Most of the settings there are pretty self-explanitory, but here's a list of the settings and what they do
  
	split on boss spawn                  (default: disabled)         Splits when a new boss spawns
	split on orb weapon                  (default: disabled)         Splits when getting the orb weapon
	split on escape                      (default: disabled)         Splits when you escape the main window
	split on boss fight start            (default: disabled)         Splits when the boss fight starts (NOTE: probably going to remove this, should always be n seconds after escaping the window)
	split on token grab                  (default: disabled)         Splits when grabbing a token
	split on perk                        (default: disabled)         Splits when losing a token (when you buy a perk)
	reset on death                       (default: enabled)	         Resets the timer when you die
	reset on exit                        (default: enabled)          Resets when quitting to title screen
	split on death                       (default: disabled)         Splits the timer when you die
