# Patch Manager - Catacombs of Solaris Revisited

A new ethical approach to modding that distributes only the differences instead of complete game files.

## Quick Start

1. Run `patch_manager.bat`
2. If it's your first time, choose `[1] Clean setup`
3. Modify files in the `extracted_game\` folder
4. Create a patch with `[3] Create patch`
5. Share the `.patch` file (not the complete game files!)

## How It Works

### Traditional Approach (Problems)
- Extract game files → Modify → Redistribute complete modified game
- **Issues**: Copyright infringement, large file sizes, version conflicts

### New Patch System (Ethical)
- Extract → Modify → Compare → Create diff file → Distribute only differences
- **Benefits**: Legal compliance, small files, version specific

## File Structure

```
game_directory/
├── patch_manager.bat          # Main interface
├── patch_manager.ps1          # PowerShell backend
├── data.pak                   # Original/current game file
├── catacombs.exe             # Game executable
├── patches/
│   ├── data_original.pak     # The original .pak file on first setup
│   ├── my_mod.patch          # Your patches
│   └── community_mod.patch   # Downloaded patches
└── extracted_game/           # Working directory
    ├── menu.lua              # Modify these files
    ├── game.lua
    └── ...
```

## Menu Options

### [1] Clean Setup
- Creates a backup of the current `data.pak`
- Sets up patch environment
- **Use when**: First time or to reset everything

### [2] Extract Content to Modify
- Extracts current `data.pak` to `extracted_game\`
- **Use when**: You want to modify existing files

### [3] Create Patch
- Compares modified files vs original
- Creates a `.patch` file with only differences
- **Use when**: You've finished your modifications

### [4] Load Patch and Restore Original
- Restores original game files
- Applies selected patch modifications
- Repackages the game
- **Use when**: Installing someone else's patch

### [5] View State
- Shows system status
- Lists available patches
- File sizes and modification dates

### [6] Open Logs Folder
- Opens game's log directory
- Useful for debugging crashes

### [7] Open Game
- Launches Catacombs of Solaris

## Patch File Format

Patches are JSON files containing:

```json
{
  "metadata": {
    "name": "My Cool Mod",
    "description": "Adds multiple gallery images",
    "author": "YourName",
    "created": "2025-08-08 10:30:00",
    "version": "1.0",
    "target_game": "Catacombs of Solaris Revisited"
  },
  "changes": [
    {
      "type": "Modified",
      "path": "menu.lua",
      "content": "<base64-encoded-file-content>"
    },
    {
      "type": "Added", 
      "path": "gallery/new_image.png",
      "content": "<base64-encoded-file-content>"
    }
  ]
}
```

## Creating Mods

### Step-by-Step Process

1. **Setup Environment**
   ```
   Run patch_manager.bat → [1] Clean setup
   ```

2. **Modify Files**
   ```
   Edit files in extracted_game\ folder
   Add new files if needed
   Test your changes
   ```

3. **Create Patch**
   ```
   Run patch_manager.bat → [3] Create patch
   Enter mod name, description, author
   ```

4. **Share Patch**
   ```
   Upload .patch file to community
   Include installation instructions
   ```

### Best Practices

- **Test thoroughly** before creating patches
- **Use descriptive names** for your patches
- **Document changes** in the description
- **Keep patches focused** on specific features
- **Include screenshots** when sharing

## Installing Community Patches

### From File

1. Download `.patch` file
2. Place in `patches\` folder
3. Run `patch_manager.bat → [4] Load patch`
4. Select your patch file

### Safety Features

- **Automatic backup** of original files
- **One-click restore** to original state
- **Patch validation** before installation
- **Error recovery** if installation fails

## Troubleshooting

### Common Issues

**"data.pak not found"**
- Make sure the files are in the game's root directory
- Verify game installation integrity

**"No original backup found"**
- Run `[1] Clean setup` to create backup
- Check `backups\` folder exists

### Log Files

Game logs location:
```
%USERPROFILE%\AppData\Roaming\Ian MacLarty\catacombs\
```

### Archive Format

- Game uses ZIP-based PAK files
- Compatible with standard ZIP tools
- PowerShell handles compression as fallback

### File Comparison

- Uses MD5 hashing for change detection
- Binary file comparison for accuracy
- Supports all file types (Lua, PNG, OBJ, etc.)

## Legal & Ethical Considerations

### What You Can Share

✅ **Allowed**
- `.patch` files you create
- Instructions and documentation
- Screenshots of your modifications
- Code snippets and tutorials

❌ **Not Allowed**
- Complete `data.pak` files
- Modified game executables
- Original game assets