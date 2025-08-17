@echo off
setlocal

rem ───────────────────────────────────────────────────────────────
rem CONFIGURATION
rem ───────────────────────────────────────────────────────────────
set "PROJECT_DIR=C:\Users\bruce\Documents\Dev\DefendTheCore"
set "LOVE_DIR=C:\Program Files\LOVE"
set "BUILD_DIR=%PROJECT_DIR%\build"
set "APP_NAME=DefendTheCore"

rem ───────────────────────────────────────────────────────────────
rem 1) Clean/build folder
rem ───────────────────────────────────────────────────────────────
if exist "%BUILD_DIR%" (
  rmdir /s /q "%BUILD_DIR%"
)
mkdir "%BUILD_DIR%"

rem ───────────────────────────────────────────────────────────────
rem 2) Create .love archive of the project
rem    Requires a zip CLI in your PATH (e.g. http://gnuwin32.sourceforge.net)
rem ───────────────────────────────────────────────────────────────
pushd "%PROJECT_DIR%"
if exist "%APP_NAME%.love" del "%APP_NAME%.love"
zip -9 -r "%APP_NAME%.love" . 
popd

rem ───────────────────────────────────────────────────────────────
rem 3) Copy LOVE2D runtime (exe + all DLLs) into build
rem ───────────────────────────────────────────────────────────────
xcopy /y "%LOVE_DIR%\love.exe" "%BUILD_DIR%" >nul
xcopy /y "%LOVE_DIR%\*.dll"   "%BUILD_DIR%" >nul

rem ───────────────────────────────────────────────────────────────
rem 4) Copy the .love archive into build dir
rem ───────────────────────────────────────────────────────────────
copy /y "%PROJECT_DIR%\%APP_NAME%.love" "%BUILD_DIR%" >nul

rem ───────────────────────────────────────────────────────────────
rem 5) Produce standalone EXE by concatenation
rem ───────────────────────────────────────────────────────────────
pushd "%BUILD_DIR%"
  rem   love.exe + DirtyTrading.love → DirtyTrading.exe
  copy /b love.exe+%APP_NAME%.love %APP_NAME%.exe >nul

  rem   cleanup intermediate files
  del love.exe
  del %APP_NAME%.love
popd

echo.
echo Done! Your standalone build is in:
echo    %BUILD_DIR%\%APP_NAME%.exe
endlocal