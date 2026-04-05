-- VRMod Semiofficial Module Installer
-- Extracts bundled module .dat files to data/vrmod_module/ and generates install script
-- Windows: Users rename install.txt -> install.bat and run it to copy DLLs to lua/bin/
-- Linux:   Users run "bash garrysmod/data/vrmod_module/install.txt" to copy SOs to lua/bin/
-- NOTE: .dat files are in data_static/ (not lua/) because GMA whitelist only allows .lua in lua/

if SERVER then return end

local TAG = "[VRMod Module] "
local DATA_DIR = "vrmod_module"
local IS_LINUX = system.IsLinux()
local IS_WINDOWS = system.IsWindows()

-- OS-conditional file table
-- Linux modules built via GitHub Actions (ubuntu-22.04, g++ -m32/-m64)
local FILES
if IS_LINUX then
	FILES = {
		{ src = "data_static/vrmod_module_bin/gmcl_vrmod_linux.dat", dst = "gmcl_vrmod_linux.dat", expectedSize = 35220 },
		{ src = "data_static/vrmod_module_bin/gmcl_vrmod_linux64.dat", dst = "gmcl_vrmod_linux64.dat", expectedSize = 41120 },
	}
else
	FILES = {
		{ src = "data_static/vrmod_module_bin/gmcl_vrmod_win32.dat", dst = "gmcl_vrmod_win32.dat", expectedSize = 169984 },
		{ src = "data_static/vrmod_module_bin/gmcl_vrmod_win64.dat", dst = "gmcl_vrmod_win64.dat", expectedSize = 197120 },
	}
end

-- Forward declarations for install script generators (defined after ExtractFiles)
local GenerateLinuxInstallScript
local GenerateWindowsInstallScript

-- Determine the correct DLL name for this platform/architecture
local function GetModuleDllName()
	if IS_LINUX then
		return jit.arch == "x64" and "gmcl_vrmod_linux64.dll" or "gmcl_vrmod_linux.dll"
	else
		return jit.arch == "x64" and "gmcl_vrmod_win64.dll" or "gmcl_vrmod_win32.dll"
	end
end

local function IsModuleInstalled()
	return g_VR and g_VR.moduleVersion and g_VR.moduleVersion > 0
end

local function IsAlreadyExtracted()
	for _, f in ipairs(FILES) do
		if not file.Exists(DATA_DIR .. "/" .. f.dst, "DATA") then return false end
	end
	if not file.Exists(DATA_DIR .. "/install.txt", "DATA") then return false end
	return true
end

-- Validate binary header based on platform
local function ValidateBinaryHeader(data, filename)
	if IS_LINUX then
		-- ELF header: 0x7F 'E' 'L' 'F'
		if #data < 4 then return false, "file too small" end
		if string.byte(data, 1) ~= 0x7F or string.byte(data, 2) ~= 0x45 or
		   string.byte(data, 3) ~= 0x4C or string.byte(data, 4) ~= 0x46 then
			return false, "not a valid ELF binary (missing ELF header)"
		end
		return true
	else
		-- PE header: 'M' 'Z'
		if #data < 2 then return false, "file too small" end
		if string.byte(data, 1) ~= 0x4D or string.byte(data, 2) ~= 0x5A then
			return false, "not a valid DLL (missing MZ header)"
		end
		return true
	end
end

local function ExtractFiles()
	file.CreateDir(DATA_DIR)

	for _, f in ipairs(FILES) do
		local src = file.Open(f.src, "rb", "GAME")
		if not src then
			print(TAG .. "ERROR: Cannot read " .. f.src)
			if IS_LINUX then
				print(TAG .. "Linux module files may not be included in this version.")
			end
			return false
		end
		local srcSize = src:Size()
		local data = src:Read(srcSize)
		src:Close()

		if not data or #data == 0 then
			print(TAG .. "ERROR: Empty data from " .. f.src)
			return false
		end

		-- Verify read completeness (catch truncation from corrupted addon cache)
		if #data ~= srcSize then
			print(TAG .. "ERROR: Read truncated for " .. f.src .. " (expected " .. srcSize .. ", got " .. #data .. ")")
			return false
		end

		-- Verify against known-good size (catches Workshop cache corruption)
		if f.expectedSize and #data ~= f.expectedSize then
			print(TAG .. "ERROR: " .. f.src .. " size mismatch (expected " .. f.expectedSize .. ", got " .. #data .. ")")
			print(TAG .. "Workshop download may be corrupted. Try resubscribing or manual download.")
			return false
		end

		-- Verify binary header (PE for Windows, ELF for Linux)
		local headerOk, headerErr = ValidateBinaryHeader(data, f.dst)
		if not headerOk then
			print(TAG .. "ERROR: " .. f.dst .. " " .. headerErr)
			print(TAG .. "Workshop download may be corrupted. Try resubscribing or manual download.")
			return false
		end

		local dst = file.Open(DATA_DIR .. "/" .. f.dst, "wb", "DATA")
		if not dst then
			print(TAG .. "ERROR: Cannot write " .. f.dst)
			return false
		end
		dst:Write(data)
		dst:Close()

		-- Verify write completeness
		local writtenSize = file.Size(DATA_DIR .. "/" .. f.dst, "DATA")
		if writtenSize ~= #data then
			print(TAG .. "ERROR: Write verification failed for " .. f.dst .. " (expected " .. #data .. ", got " .. tostring(writtenSize) .. ")")
			return false
		end

		print(TAG .. "Extracted " .. f.dst .. " (" .. #data .. " bytes) [verified]")
	end

	-- Generate platform-appropriate install script
	local script
	if IS_LINUX then
		script = GenerateLinuxInstallScript()
	else
		script = GenerateWindowsInstallScript()
	end

	file.Write(DATA_DIR .. "/install.txt", script)

	-- Verify install script was generated (file.Write is void, can fail silently)
	if not file.Exists(DATA_DIR .. "/install.txt", "DATA") or file.Size(DATA_DIR .. "/install.txt", "DATA") == 0 then
		print(TAG .. "ERROR: Failed to generate install.txt (disk full?)")
		return false
	end

	print(TAG .. "Generated install.txt")
	return true
end

GenerateLinuxInstallScript = function()
	local sh = "#!/bin/bash\n"
	sh = sh .. "echo '============================================'\n"
	sh = sh .. "echo ' VRMod Semiofficial Module Installer (Linux)'\n"
	sh = sh .. "echo '============================================'\n"
	sh = sh .. "echo ''\n"
	sh = sh .. 'SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"\n'
	sh = sh .. 'DST="$SCRIPT_DIR/../../lua/bin"\n'
	sh = sh .. 'FAIL=0\n'
	sh = sh .. "\n"
	-- Create directory
	sh = sh .. 'mkdir -p "$DST" 2>/dev/null\n'
	sh = sh .. 'if [ ! -d "$DST" ]; then\n'
	sh = sh .. "    echo '[ERROR] Failed to create lua/bin directory.'\n"
	sh = sh .. "    echo 'Try: sudo bash install.txt'\n"
	sh = sh .. "    exit 1\n"
	sh = sh .. "fi\n"
	sh = sh .. "echo ''\n"
	-- Copy files
	sh = sh .. 'cp "$SCRIPT_DIR/gmcl_vrmod_linux.dat" "$DST/gmcl_vrmod_linux.dll" 2>/dev/null\n'
	sh = sh .. "if [ $? -eq 0 ]; then\n"
	sh = sh .. "    echo '[OK] gmcl_vrmod_linux.dll'\n"
	sh = sh .. "else\n"
	sh = sh .. "    echo '[FAIL] gmcl_vrmod_linux.dll'\n"
	sh = sh .. "    FAIL=1\n"
	sh = sh .. "fi\n"
	sh = sh .. 'cp "$SCRIPT_DIR/gmcl_vrmod_linux64.dat" "$DST/gmcl_vrmod_linux64.dll" 2>/dev/null\n'
	sh = sh .. "if [ $? -eq 0 ]; then\n"
	sh = sh .. "    echo '[OK] gmcl_vrmod_linux64.dll'\n"
	sh = sh .. "else\n"
	sh = sh .. "    echo '[FAIL] gmcl_vrmod_linux64.dll'\n"
	sh = sh .. "    FAIL=1\n"
	sh = sh .. "fi\n"
	sh = sh .. "echo ''\n"
	-- Post-copy verification
	sh = sh .. 'if [ ! -f "$DST/gmcl_vrmod_linux.dll" ]; then\n'
	sh = sh .. "    echo '[WARN] gmcl_vrmod_linux.dll not found after copy!'\n"
	sh = sh .. "    FAIL=1\n"
	sh = sh .. "fi\n"
	sh = sh .. 'if [ ! -f "$DST/gmcl_vrmod_linux64.dll" ]; then\n'
	sh = sh .. "    echo '[WARN] gmcl_vrmod_linux64.dll not found after copy!'\n"
	sh = sh .. "    FAIL=1\n"
	sh = sh .. "fi\n"
	-- Size verification
	sh = sh .. 'SRC32=$(stat -c %s "$SCRIPT_DIR/gmcl_vrmod_linux.dat" 2>/dev/null)\n'
	sh = sh .. 'DST32=$(stat -c %s "$DST/gmcl_vrmod_linux.dll" 2>/dev/null)\n'
	sh = sh .. 'if [ "$SRC32" != "$DST32" ]; then\n'
	sh = sh .. "    echo '[ERROR] gmcl_vrmod_linux.dll size mismatch. File may be corrupted.'\n"
	sh = sh .. "    FAIL=1\n"
	sh = sh .. "fi\n"
	sh = sh .. 'SRC64=$(stat -c %s "$SCRIPT_DIR/gmcl_vrmod_linux64.dat" 2>/dev/null)\n'
	sh = sh .. 'DST64=$(stat -c %s "$DST/gmcl_vrmod_linux64.dll" 2>/dev/null)\n'
	sh = sh .. 'if [ "$SRC64" != "$DST64" ]; then\n'
	sh = sh .. "    echo '[ERROR] gmcl_vrmod_linux64.dll size mismatch. File may be corrupted.'\n"
	sh = sh .. "    FAIL=1\n"
	sh = sh .. "fi\n"
	sh = sh .. "echo ''\n"
	-- Result
	sh = sh .. 'if [ "$FAIL" -eq 1 ]; then\n'
	sh = sh .. "    echo '============================================'\n"
	sh = sh .. "    echo ' INSTALLATION FAILED'\n"
	sh = sh .. "    echo '============================================'\n"
	sh = sh .. "    echo ''\n"
	sh = sh .. "    echo 'Common causes:'\n"
	sh = sh .. "    echo '  1. Garry s Mod is still running. Close it first.'\n"
	sh = sh .. "    echo '  2. Permission issue. Try: sudo bash install.txt'\n"
	sh = sh .. "else\n"
	sh = sh .. "    echo '============================================'\n"
	sh = sh .. "    echo ' Installation successful!'\n"
	sh = sh .. "    echo ' Please restart Garry s Mod.'\n"
	sh = sh .. "    echo '============================================'\n"
	sh = sh .. "fi\n"
	sh = sh .. "echo ''\n"
	return sh
end

GenerateWindowsInstallScript = function()
	local bat = "@echo off\r\n"
	bat = bat .. "chcp 65001 >nul 2>&1\r\n"
	bat = bat .. "echo ============================================\r\n"
	bat = bat .. "echo  VRMod Semiofficial Module Installer\r\n"
	bat = bat .. "echo ============================================\r\n"
	bat = bat .. "echo.\r\n"
	bat = bat .. 'set "DST=%~dp0..\\..\\lua\\bin"\r\n'
	bat = bat .. 'set "FAIL=0"\r\n'
	bat = bat .. 'if not exist "%DST%" mkdir "%DST%" 2>nul\r\n'
	bat = bat .. 'if not exist "%DST%" (\r\n'
	bat = bat .. "    echo [ERROR] Failed to create lua\\bin directory.\r\n"
	bat = bat .. "    echo Try: Right-click install.bat, Run as administrator.\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. "    goto :RESULT\r\n"
	bat = bat .. ")\r\n"
	bat = bat .. "echo.\r\n"
	bat = bat .. 'copy /B /Y "%~dp0gmcl_vrmod_win32.dat" "%DST%\\gmcl_vrmod_win32.dll" >nul 2>&1\r\n'
	bat = bat .. "if errorlevel 1 (\r\n"
	bat = bat .. "    echo [FAIL] gmcl_vrmod_win32.dll\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. ") else (\r\n"
	bat = bat .. "    echo [OK] gmcl_vrmod_win32.dll\r\n"
	bat = bat .. ")\r\n"
	bat = bat .. 'copy /B /Y "%~dp0gmcl_vrmod_win64.dat" "%DST%\\gmcl_vrmod_win64.dll" >nul 2>&1\r\n'
	bat = bat .. "if errorlevel 1 (\r\n"
	bat = bat .. "    echo [FAIL] gmcl_vrmod_win64.dll\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. ") else (\r\n"
	bat = bat .. "    echo [OK] gmcl_vrmod_win64.dll\r\n"
	bat = bat .. ")\r\n"
	bat = bat .. "echo.\r\n"
	-- Post-copy verification: detect antivirus quarantine
	bat = bat .. 'if not exist "%DST%\\gmcl_vrmod_win32.dll" (\r\n'
	bat = bat .. "    echo [WARN] gmcl_vrmod_win32.dll disappeared after copy!\r\n"
	bat = bat .. "    echo        Antivirus may have quarantined it.\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. ")\r\n"
	bat = bat .. 'if not exist "%DST%\\gmcl_vrmod_win64.dll" (\r\n'
	bat = bat .. "    echo [WARN] gmcl_vrmod_win64.dll disappeared after copy!\r\n"
	bat = bat .. "    echo        Antivirus may have quarantined it.\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. ")\r\n"
	-- Post-copy size verification (catches partial copy from disk full, etc.)
	bat = bat .. 'for %%F in ("%~dp0gmcl_vrmod_win32.dat") do set "SRC32=%%~zF"\r\n'
	bat = bat .. 'for %%F in ("%DST%\\gmcl_vrmod_win32.dll") do set "DST32=%%~zF"\r\n'
	bat = bat .. 'if not "%SRC32%"=="%DST32%" (\r\n'
	bat = bat .. "    echo [ERROR] gmcl_vrmod_win32.dll size mismatch. File may be corrupted.\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. ")\r\n"
	bat = bat .. 'for %%F in ("%~dp0gmcl_vrmod_win64.dat") do set "SRC64=%%~zF"\r\n'
	bat = bat .. 'for %%F in ("%DST%\\gmcl_vrmod_win64.dll") do set "DST64=%%~zF"\r\n'
	bat = bat .. 'if not "%SRC64%"=="%DST64%" (\r\n'
	bat = bat .. "    echo [ERROR] gmcl_vrmod_win64.dll size mismatch. File may be corrupted.\r\n"
	bat = bat .. '    set "FAIL=1"\r\n'
	bat = bat .. ")\r\n"
	bat = bat .. ":RESULT\r\n"
	bat = bat .. "echo.\r\n"
	bat = bat .. 'if "%FAIL%"=="1" goto :FAILMSG\r\n'
	bat = bat .. "echo ============================================\r\n"
	bat = bat .. "echo  Installation successful!\r\n"
	bat = bat .. "echo  Please restart Garry's Mod.\r\n"
	bat = bat .. "echo ============================================\r\n"
	bat = bat .. "goto :END\r\n"
	bat = bat .. ":FAILMSG\r\n"
	bat = bat .. "echo ============================================\r\n"
	bat = bat .. "echo  INSTALLATION FAILED\r\n"
	bat = bat .. "echo ============================================\r\n"
	bat = bat .. "echo.\r\n"
	bat = bat .. "echo Common causes:\r\n"
	bat = bat .. "echo  1. Garry's Mod is still running. Close it first.\r\n"
	bat = bat .. "echo  2. Antivirus quarantined the DLL files.\r\n"
	bat = bat .. "echo     Fix: Add your GarrysMod folder to AV exclusions.\r\n"
	bat = bat .. "echo     Windows Defender: Settings - Virus protection - Exclusions\r\n"
	bat = bat .. "echo  3. Need admin rights. Right-click, Run as administrator.\r\n"
	bat = bat .. "echo.\r\n"
	bat = bat .. "echo If the problem persists, see the Workshop description\r\n"
	bat = bat .. "echo for a manual download link.\r\n"
	bat = bat .. ":END\r\n"
	bat = bat .. "echo.\r\n"
	bat = bat .. "pause\r\n"
	return bat
end

local function PrintInstallGuide()
	print("")
	print("==============================================")
	print(TAG .. "Module not installed!")
	if IS_LINUX then
		print(TAG .. "To install:")
		print(TAG .. "  1. Open a terminal")
		print(TAG .. "  2. Run: bash garrysmod/data/" .. DATA_DIR .. "/install.txt")
		print(TAG .. "  3. Restart Garry's Mod")
	else
		print(TAG .. "To install:")
		print(TAG .. "  1. Go to: garrysmod/data/" .. DATA_DIR .. "/")
		print(TAG .. "  2. Rename 'install.txt' to 'install.bat'")
		print(TAG .. "  3. Run install.bat")
		print(TAG .. "  4. Restart Garry's Mod")
	end
	print("==============================================")
	print("")
end

local function ShowChatGuide()
	if IsModuleInstalled() then return end
	if IS_LINUX then
		chat.AddText(
			Color(255, 200, 0), "[VRMod] ",
			Color(255, 255, 255), "Module not installed. Run: ",
			Color(100, 255, 100), "bash garrysmod/data/" .. DATA_DIR .. "/install.txt"
		)
	else
		chat.AddText(
			Color(255, 200, 0), "[VRMod] ",
			Color(255, 255, 255), "Module not installed. Go to ",
			Color(100, 255, 100), "garrysmod/data/" .. DATA_DIR .. "/",
			Color(255, 255, 255), " -> rename install.txt -> install.bat -> run it"
		)
	end
end

-- Main logic
local function Run()
	if IsModuleInstalled() then
		print(TAG .. "Module loaded. Skipping extraction.")
		return
	end

	local dllName = GetModuleDllName()
	local installCmd = IS_LINUX and "bash install.txt" or "install.bat"

	if IsAlreadyExtracted() then
		if file.Exists("lua/bin/" .. dllName, "GAME") then
			print(TAG .. "Module DLL found but failed to load. Try: vrmod_module_extract")
			if not IS_LINUX then
				print(TAG .. "If antivirus removed it, add GarrysMod folder to AV exclusions.")
			end
		else
			print(TAG .. "Module not installed. Run " .. installCmd .. " (Gmod update may have removed it)")
		end
		PrintInstallGuide()
	else
		print(TAG .. "Extracting module files...")
		if ExtractFiles() then
			print(TAG .. "Extraction complete!")
			PrintInstallGuide()
		end
	end

	-- Chat notification after game is fully loaded
	hook.Add("InitPostEntity", "VRMod_ModuleInstallGuide", function()
		hook.Remove("InitPostEntity", "VRMod_ModuleInstallGuide")
		timer.Simple(3, ShowChatGuide)
	end)
end

-- Manual re-extract command
concommand.Add("vrmod_module_extract", function()
	print(TAG .. "Force re-extracting module files...")
	if ExtractFiles() then
		print(TAG .. "Re-extraction complete!")
		PrintInstallGuide()
	end
end)

-- Global function for menu integration
function vrmod_OpenModuleFolder()
	PrintInstallGuide()
	if IS_LINUX then
		chat.AddText(
			Color(255, 200, 0), "[VRMod] ",
			Color(255, 255, 255), "Run in terminal: ",
			Color(100, 255, 100), "bash garrysmod/data/" .. DATA_DIR .. "/install.txt"
		)
	else
		-- gui.OpenURL("file:///") with relative path doesn't work
		-- Show clear instructions in chat instead
		chat.AddText(
			Color(255, 200, 0), "[VRMod] ",
			Color(255, 255, 255), "In Steam: Right-click Garry's Mod > Manage > Browse Local Files"
		)
		chat.AddText(
			Color(255, 200, 0), "[VRMod] ",
			Color(255, 255, 255), "Then go to: ",
			Color(100, 255, 100), "garrysmod\\data\\" .. DATA_DIR .. "\\"
		)
	end
end

-- Run on load
Run()
