@echo off
setlocal enabledelayedexpansion
title Patch Manager - Catacombs of Solaris Revisited
color 0B

rem Check if this is first run (no patches or extracted_game folders)
set "FIRST_RUN=false"
if not exist "patches/data_original.pak" if not exist "extracted_game" set "FIRST_RUN=true"

:menu
cls
echo ===============================================
echo    PATCH MANAGER - Catacombs of Solaris
echo ===============================================

rem Clear any previous input buffer
set "choice="

if "%FIRST_RUN%"=="true" (
    echo.
    echo FIRST TIME SETUP REQUIRED
    echo.
    echo [1] Clean setup ^(extract original game files^)
    echo [2] Exit
    echo.
    set /p "choice=Choose option (1-2): "
    
    if "!choice!"=="1" goto clean_setup
    if "!choice!"=="2" goto exit
    echo Invalid choice. Please try again.
    timeout /t 2 >nul
    goto menu
) else (
    echo.
    echo Select an option:
    echo.
    echo [1] Clean setup ^(reset to original^)
    echo [2] Extract content to modify
    echo [3] Create patch
    echo [4] Load patch and restore original files
    echo [5] Build and Test ^(temporary package for testing^)
    echo [6] View state
    echo [7] Open logs folder
    echo [8] Open game
    echo [9] Exit
    echo.
    set /p "choice=Choose option (1-9): "
    
    if "!choice!"=="1" goto clean_setup
    if "!choice!"=="2" goto extract
    if "!choice!"=="3" goto create_patch
    if "!choice!"=="4" goto load_patch
    if "!choice!"=="5" goto build_test
    if "!choice!"=="6" goto view_state
    if "!choice!"=="7" goto open_logs
    if "!choice!"=="8" goto run_game
    if "!choice!"=="9" goto exit
    echo Invalid choice. Please try again.
    timeout /t 2 >nul
    goto menu
)

:clean_setup
cls
echo ===============================================
echo              CLEAN SETUP
echo ===============================================
echo.
echo This will:
echo 1. Extract original data.pak
echo 2. Create patches folder
echo 3. Create backup of original files in patches\
echo 4. Set up patch management system
echo.
echo WARNING: This will remove any existing modifications!
echo.
set "confirm="
set /p "confirm=Continue? (y/N): "
if /i not "!confirm!"=="y" goto menu

echo.
echo Setting up patch management system...

rem Create necessary folders
if not exist "patches" mkdir "patches"

rem Backup original data.pak if not already done
if not exist "patches\data_original.pak" (
    echo Backing up original data.pak...
    copy "data.pak" "patches\data_original.pak" >nul
    if errorlevel 1 (
        echo ERROR: Could not backup original data.pak
        pause
        goto menu
    )
    echo Original backup created successfully in patches\
)

rem Extract original content
echo.
echo Extracting original game content...
powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" extract_original
if errorlevel 1 (
    echo ERROR: Failed to extract original content
    pause
    goto menu
)

echo.
echo Clean setup completed successfully!
echo You can now modify files in extracted_game\ folder.
set "FIRST_RUN=false"
pause
goto menu

:extract
cls
echo ===============================================
echo           EXTRACT CONTENT TO MODIFY
echo ===============================================
echo.
echo This will extract the current data.pak for modification.
echo Any existing extracted_game\ folder will be overwritten.
echo.
set "confirm="
set /p "confirm=Continue? (y/N): "
if /i not "!confirm!"=="y" goto menu

echo.
echo Extracting content...
powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" extract_current
pause
goto menu

:create_patch
cls
echo ===============================================
echo              CREATE PATCH
echo ===============================================
echo.
echo This will create a patch file containing only the differences
echo between your modified files and the original game files.
echo.

rem Check if extracted_game exists
if not exist "extracted_game" (
    echo ERROR: No extracted game files found.
    echo Please run "Extract content to modify" first.
    pause
    goto menu
)

rem Check if original backup exists
if not exist "patches\data_original.pak" (
    echo ERROR: No original backup found.
    echo Please run "Clean setup" first.
    pause
    goto menu
)

echo Enter patch information:
echo.
set "patch_name="
set "patch_desc="
set "patch_author="
set /p "patch_name=Patch name (no spaces): "
if "!patch_name!"=="" set "patch_name=unnamed_patch"

set /p "patch_desc=Patch description: "
if "!patch_desc!"=="" set "patch_desc=No description provided"

set /p "patch_author=Author name: "
if "!patch_author!"=="" set "patch_author=Anonymous"

echo.
echo Creating patch: !patch_name!
echo Description: !patch_desc!
echo Author: !patch_author!
echo.
echo Processing differences...

powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" create_patch "!patch_name!" "!patch_desc!" "!patch_author!"
pause
goto menu

:load_patch
cls
echo ===============================================
echo        LOAD PATCH AND RESTORE ORIGINAL
echo ===============================================
echo.
echo Available options:
echo.
echo [0] Restore original game files only

rem Show patch list using PowerShell
powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" show_patch_list

rem Count patches for validation
set patch_count=0
if exist "patches\*.patch" (
    for %%f in ("patches\*.patch") do (
        set /a patch_count+=1
    )
) 

if %patch_count%==0 (
    echo.
    echo No patches found in patches\ folder.
    echo.
    echo To get patches:
    echo - Create your own using "Create patch"
    echo - Download patches from the community
    echo - Place .patch files in the patches\ folder
    echo.
    echo You can still choose [0] to restore original files.
)

echo.
set "patch_choice="
set /p "patch_choice=Choose option (0-%patch_count%): "

if "!patch_choice!"=="0" (
    echo.
    echo Restoring original game files...
    powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" restore_original
) else (
    if !patch_choice! LEQ %patch_count% if !patch_choice! GEQ 1 (
        echo.
        echo Loading patch number !patch_choice!...
        powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" load_patch_by_number "!patch_choice!"
    ) else (
        echo Invalid choice. Please try again.
        timeout /t 2 >nul
        goto load_patch
    )
)
pause
goto menu

:build_test
cls
echo ===============================================
echo              BUILD AND TEST
echo ===============================================
echo.
echo This will temporarily package your current modifications
echo and launch the game for testing. No permanent patch is created.
echo.

rem Check if extracted_game exists
if not exist "extracted_game" (
    echo ERROR: No extracted_game folder found.
    echo Please use option 2 "Extract content to modify" first.
    echo.
    pause
    goto menu
)

echo Creating temporary package for testing...
echo.

rem Create temporary backup of current data.pak
if exist "data.pak" (
    echo Backing up current data.pak...
    copy "data.pak" "data_temp_backup.pak" >nul 2>&1
)

rem Package current modifications into data.pak
echo Packaging modifications...
powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" build_temp_package

if errorlevel 1 (
    echo.
    echo ERROR: Failed to create temporary package.
    rem Restore backup if it exists
    if exist "data_temp_backup.pak" (
        echo Restoring original data.pak...
        copy "data_temp_backup.pak" "data.pak" >nul 2>&1
        del "data_temp_backup.pak" >nul 2>&1
    )
    pause
    goto menu
)

echo.
echo Temporary package created successfully!
echo Launching game...
echo.

rem Wait a moment to ensure file handles are released
timeout /t 2 >nul

rem Check if game executable exists
if not exist "catacombs.exe" (
    echo ERROR: catacombs.exe not found in current directory.
    echo Current directory: "%CD%"
    pause
    goto restore_after_test
)

rem Verify data.pak is accessible
echo Verifying temporary package...
if exist "data.pak" (
    for %%A in ("data.pak") do (
        if %%~zA LSS 1000 (
            echo WARNING: data.pak seems too small ^(%%~zA bytes^)
            echo This might indicate a packaging error.
        ) else (
            echo data.pak ready ^(%%~zA bytes^)
        )
    )
) else (
    echo ERROR: data.pak not found after packaging!
    goto restore_after_test
)

rem Check for required DLL files
echo Checking game dependencies...
set "missing_files="
if not exist "SDL2.dll" set "missing_files=!missing_files! SDL2.dll"
if not exist "libEGL.dll" set "missing_files=!missing_files! libEGL.dll"
if not exist "libGLESv2.dll" set "missing_files=!missing_files! libGLESv2.dll"
if not exist "d3dcompiler_47.dll" set "missing_files=!missing_files! d3dcompiler_47.dll"

if not "!missing_files!"=="" (
    echo WARNING: Missing DLL files: !missing_files!
    echo The game might crash due to missing dependencies.
    echo.
    set /p "continue=Continue anyway? (y/N): "
    if /i not "!continue!"=="y" goto restore_after_test
)

rem Test if the game can at least start
echo Testing game startup (this may take a moment)...
timeout /t 1 >nul

rem Launch the game with proper working directory and detached process
echo Starting catacombs.exe...
echo.
echo IMPORTANT: 
echo - The game will start and this window will wait for it to close
echo - If the game crashes, you can open the logs folder from the menu
echo - Close the game normally to automatically restore original files
echo.
echo Starting game now...

rem Try to launch the game and capture any immediate errors
"%CD%\catacombs.exe"

echo Game process has ended. Restoring original files...

:restore_after_test
echo.
echo Restoring original data.pak...
if exist "data_temp_backup.pak" (
    copy "data_temp_backup.pak" "data.pak" >nul 2>&1
    del "data_temp_backup.pak" >nul 2>&1
    echo Original files restored.
) else (
    echo Restoring from patches backup...
    if exist "patches\data_original.pak" (
        copy "patches\data_original.pak" "data.pak" >nul 2>&1
        echo Original files restored from patches backup.
    ) else (
        echo WARNING: Could not restore original files!
        echo You may need to restore manually.
    )
)

echo.
echo Build and test complete.
pause
goto menu

:view_state
cls
echo ===============================================
echo               SYSTEM STATE
echo ===============================================
echo.
powershell.exe -ExecutionPolicy Bypass -File ".\patch_manager.ps1" show_state
pause
goto menu

:open_logs
cls
echo Opening game logs folder...
echo.
echo Location: %USERPROFILE%\AppData\Roaming\Ian MacLarty\catacombs
echo.
if exist "%USERPROFILE%\AppData\Roaming\Ian MacLarty\catacombs" (
    explorer "%USERPROFILE%\AppData\Roaming\Ian MacLarty\catacombs"
    echo Folder opened in explorer.
    echo.
    echo Here you can find:
    echo - Game log files
    echo - Crash information
    echo - Saved configurations
    timeout /t 3 >nul
) else (
    echo ERROR: Logs folder not found.
    echo The folder is created automatically when the game runs for the first time.
    echo.
    echo If the problem persists, verify that the game has been run at least once.
    pause
)
goto menu

:run_game
cls
echo Running the game...
echo.
if exist "catacombs.exe" (
    start "" "catacombs.exe"
    echo Game started!
    timeout /t 2 >nul
) else (
    echo ERROR: catacombs.exe not found
    echo Make sure you're in the correct game directory.
    pause
)
goto menu

:exit
echo.
echo Thanks for using Patch Manager!
timeout /t 2 >nul
exit
