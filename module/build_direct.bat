@echo off
set "MSVC=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133"
set "WINSDK=C:\Program Files (x86)\Windows Kits\10"
set "SDKVER=10.0.22621.0"
set "SRCDIR=R:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\vrmod_semioffcial\module"
set "OUTDIR=%SRCDIR%\install\GarrysMod\garrysmod\lua\bin"

echo === Building x86 ===
set "PATH=%MSVC%\bin\Hostx86\x86;%WINSDK%\bin\%SDKVER%\x86;%PATH%"
set "INCLUDE=%MSVC%\include;%WINSDK%\Include\%SDKVER%\ucrt;%WINSDK%\Include\%SDKVER%\um;%WINSDK%\Include\%SDKVER%\shared"
set "LIB=%MSVC%\lib\x86;%WINSDK%\Lib\%SDKVER%\ucrt\x86;%WINSDK%\Lib\%SDKVER%\um\x86"

cd /d "%OUTDIR%"
cl -MT -nologo -Oi -O2 -W3 /wd4996 /I"%SRCDIR%\deps" "%SRCDIR%\src\vrmod.cpp" /link -INCREMENTAL:NO -opt:ref d3d11.lib USER32.LIB /LIBPATH:"%SRCDIR%\deps\openvr" /LIBPATH:"%SRCDIR%\deps\sranipal" openvr_api_win32.lib /DLL /out:"%OUTDIR%\gmcl_vrmod_win32.dll"
if errorlevel 1 (
    echo BUILD_FAILED_x86
    exit /b 1
)
del vrmod.obj gmcl_vrmod_win32.exp gmcl_vrmod_win32.lib 2>/dev/null
echo BUILD_OK_x86

echo === Building x64 ===
set "PATH=%MSVC%\bin\Hostx64\x64;%WINSDK%\bin\%SDKVER%\x64;%PATH%"
set "INCLUDE=%MSVC%\include;%WINSDK%\Include\%SDKVER%\ucrt;%WINSDK%\Include\%SDKVER%\um;%WINSDK%\Include\%SDKVER%\shared"
set "LIB=%MSVC%\lib\x64;%WINSDK%\Lib\%SDKVER%\ucrt\x64;%WINSDK%\Lib\%SDKVER%\um\x64"

cl -MT -nologo -Oi -O2 -W3 /wd4996 /I"%SRCDIR%\deps" "%SRCDIR%\src\vrmod.cpp" /link -INCREMENTAL:NO -opt:ref d3d11.lib USER32.LIB /LIBPATH:"%SRCDIR%\deps\openvr" /LIBPATH:"%SRCDIR%\deps\sranipal" openvr_api_win64.lib /DLL /out:"%OUTDIR%\gmcl_vrmod_win64.dll"
if errorlevel 1 (
    echo BUILD_FAILED_x64
    exit /b 1
)
del vrmod.obj gmcl_vrmod_win64.exp gmcl_vrmod_win64.lib 2>/dev/null
echo BUILD_OK_x64

echo === ALL_DONE ===
