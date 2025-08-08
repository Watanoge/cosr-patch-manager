# Patch Manager for The Catacombs of Solaris Revisited

Originally built for The Catacombs of Solaris Revisited, but the general process should work with any Amulet engine game (though the log opening feature is COSR-specific).

## Installation

Drop these files into your game's root folder:

1. **Find your game folder**
   - Steam: Right-click the game → Properties → Local Files → Browse
   - Usually something like: `C:\Program Files (x86)\Steam\steamapps\common\The Catacombs of Solaris Revisited`

2. **Copy these files there**:
   - `patch_manager.bat`
   - `patch_manager.ps1`
   - `/patches/` this folder contains some basic QOL patches ready to install
   
3. **That's it!** You should see them next to `catacombs.exe` and `data.pak`

## Quick Start

1. Double-click `patch_manager.bat`
2. Choose `[1] Clean setup` to get everything ready
3. Edit files in the `extracted_game\` folder that gets created
5. Use `[5] Build and Test` to test your changes live
4. When you're done, use `[3] Create patch` to package your changes
5. Share your `.patch` file with the community!

## What You'll See

```
your_game_folder/
├── patch_manager.bat          # Double-click this to start
├── patch_manager.ps1          # The behind-the-scenes magic
├── data.pak                   # Your game's content file
├── catacombs.exe             # The actual game
├── patches/
│   ├── data_original.pak     # Backup of the original game
│   ├── my_awesome_mod.patch  # Your creations
│   └── someones_mod.patch    # Downloaded mods
└── extracted_game/           # Your modding workspace
    ├── menu.lua              # Edit these files to your heart's content
    ├── game.lua
    └── ... (all the other game files)
```

## The Menu Breakdown

### [1] Load Patch, or Restore Original Files
- Puts the game back to vanilla
- Applies someone else's patch
- Rebuilds everything
- **Use this**: Installing downloaded mods or restoring original game files

### [2] Extract Content to Modify
- Unpacks your game files into `extracted_game\`
- **Use this**: When you want to start modding existing files

### [3] Build and Test
- Temporarily packages your current work
- Launches the game for testing
- Automatically restores original files when game closes
- **Use this**: Testing your changes without creating a permanent patch

### [4] Create Patch
- Compares your changes vs the original
- Makes a tiny `.patch` file with just your modifications
- **Use this**: When you're done modding and want to share

### [5] View State
- Shows what's going on with your setup
- Lists available patches and file info

### [6] Open Logs Folder
- Opens the game's crash log folder (COSR-specific)
- Handy for debugging when things go wrong

### [7] Open Game
- Just launches the game normally

### [8] Exit
- Exits the patch manager

## Installing Other People's Mods

1. Download the `.patch` file
2. Toss it in your `patches\` folder  
3. Run `patch_manager.bat → [4] Load patch`
4. Pick the patch from the list
5. Enjoy!

## When Things Go Wrong

### "Oops, data.pak not found!"
- Double-check you put the files in the right game folder
- Maybe verify your game files through Steam?

### "Where's my original backup?"
- Check inside the `patches` folder for `data_original.pak`
- Run `[4] Load Patch and Restore Original` and pick option 0 to load the original `data.pak` file

### Game Crashes?
Check the logs at:
```
%USERPROFILE%\AppData\Roaming\Ian MacLarty\catacombs\
```
(That's `[7] Open Logs Folder` for convenience!)

## Technical Stuff (For the Curious)

### Under the Hood
- Game files are basically ZIP files with a different name
- We use PowerShell for the heavy lifting
- MD5 hashes help us spot what actually changed
- Works with any file type (code, images, 3D models, whatever)

## What's Cool to Share vs. What's Not

### ✅ Totally Fine
- Your `.patch` files
- Setup guides and tutorials  
- Screenshots of your awesome mods
- Code snippets and tips

### ❌ Please Don't
- Complete `data.pak` files
- The actual game executable
- Original game assets
- Anything that's basically piracy

---

*Remember: This tool was made specifically for COSR, but the general approach should work with other Amulet engine games too. Just don't expect the logs folder thing to work elsewhere!*