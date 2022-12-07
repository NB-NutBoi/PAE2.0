@echo off
set /p targetBuild=State target platform [windows/mac/linux]: 
echo Building for %targetBuild%...
lime build %targetBuild%
echo  &echo:&echo:&echo:
echo Build process complete. check results and press any key to close the window.
pause >nul