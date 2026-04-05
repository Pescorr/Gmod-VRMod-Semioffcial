@echo off
set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
set "SRCDIR=R:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\vrmod_semioffcial\module"
set "OUTDIR=%SRCDIR%\install\GarrysMod\garrysmod\lua\bin"
set "LOGFILE=%SRCDIR%\build_log.txt"
echo Build started > "%LOGFILE%"
call "%VCVARS%" x64 >/dev/null 2>&1
pushd "%OUTDIR%"
cl -MT -nologo -Oi -O2 -W3 /wd4996 /I"%SRCDIR%\deps" "%SRCDIR%\src\vrmod.cpp" /link -INCREMENTAL:NO -opt:ref d3d11.lib USER32.LIB /LIBPATH:"%SRCDIR%\deps\openvr" /DLL openvr_api_win64.lib /out:gmcl_vrmod_win64.dll >> "%LOGFILE%" 2>&1
echo x64 exit: %errorlevel% >> "%LOGFILE%"
del vrmod.obj gmcl_vrmod_win64.exp gmcl_vrmod_win64.lib 2>/dev/null
call "%VCVARS%" x86 >/dev/null 2>&1
cl -MT -nologo -Oi -O2 -W3 /wd4996 /I"%SRCDIR%\deps" "%SRCDIR%\src\vrmod.cpp" /link -INCREMENTAL:NO -opt:ref d3d11.lib USER32.LIB /LIBPATH:"%SRCDIR%\deps\openvr" /DLL openvr_api_win32.lib /out:gmcl_vrmod_win32.dll >> "%LOGFILE%" 2>&1
echo x86 exit: %errorlevel% >> "%LOGFILE%"
del vrmod.obj gmcl_vrmod_win32.exp gmcl_vrmod_win32.lib 2>/dev/null
popd
dir "%OUTDIR%\gmcl_vrmod_win*.dll" >> "%LOGFILE%" 2>&1
echo DONE >> "%LOGFILE%"
