@echo off
REM VRMod Semiofficial Module - Build Script
REM Requires Visual Studio 2019 or 2022 with C++ Desktop Development workload

set "VCVARS=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
set "SRCDIR=%~dp0"
set "OUTDIR=%SRCDIR%install\GarrysMod\garrysmod\lua\bin"

if not exist "%VCVARS%" (
    echo ERROR: vcvarsall.bat not found at %VCVARS%
    echo Edit this script to set the correct path.
    pause
    exit /b 1
)

if not exist "%SRCDIR%deps\openvr\openvr.h" (
    echo ERROR: deps not found. Place OpenVR headers and libs in deps\openvr\
    pause
    exit /b 1
)

REM Check for optional SRanipal
if exist "%SRCDIR%deps\sranipal\" (
    set "SRANIPAL=/DVRMOD_USE_SRANIPAL"
    echo SRanipal SDK found - building with eye/lip tracking support
) else (
    set "SRANIPAL="
    echo SRanipal SDK not found - building without
)

set "CFLAGS=-MT -nologo -Oi -O2 -W3 /wd4996 /I"%SRCDIR%deps""
set "LFLAGS=-INCREMENTAL:NO -opt:ref d3d11.lib USER32.LIB /LIBPATH:"%SRCDIR%deps\openvr" /LIBPATH:"%SRCDIR%deps\sranipal" /DLL"

pushd "%OUTDIR%"

echo === Building x64 ===
call "%VCVARS%" x64 >nul 2>&1
cl %CFLAGS% %SRANIPAL% "%SRCDIR%src\vrmod.cpp" /link %LFLAGS% openvr_api_win64.lib /out:gmcl_vrmod_win64.dll
if errorlevel 1 (
    echo ERROR: x64 build failed
    popd
    pause
    exit /b 1
)
del vrmod.obj gmcl_vrmod_win64.exp gmcl_vrmod_win64.lib 2>nul
echo x64 OK

echo === Building x86 ===
call "%VCVARS%" x86 >nul 2>&1
cl %CFLAGS% %SRANIPAL% "%SRCDIR%src\vrmod.cpp" /link %LFLAGS% openvr_api_win32.lib /out:gmcl_vrmod_win32.dll
if errorlevel 1 (
    echo ERROR: x86 build failed
    popd
    pause
    exit /b 1
)
del vrmod.obj gmcl_vrmod_win32.exp gmcl_vrmod_win32.lib 2>nul
echo x86 OK

popd

echo.
echo === Build Complete ===
dir "%OUTDIR%\gmcl_vrmod_win*.dll"
echo.
pause
