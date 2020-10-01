@echo off

setlocal

set "TEST_ROOT=%~dp0"

set TEST_SVN_TOOLSET_LIST=^
tortoisesvn-win32 "1.9.5.27581-1.9.5/bin|1.8.12.26645-1.8.14/bin|1.7.15.25753-1.7.18/bin" ^
collabnet-win32 "1.9.5-1/bin|1.8.17-1/bin|1.7.19-1/bin" ^
sliksvn-win32 "1.9.5/bin|1.8.17/bin|1.7.22/bin" ^
cygwin-win32 "1.9.5-1/bin|1.8.17-1/bin|1.7.14-1/bin" ^
visualsvn-win32 "1.9.5/bin" ^
win32svn "1.8.17/bin|1.7.22/bin"

set TOOLSET_LIST_INDEX=0
for %%i in (%TEST_SVN_TOOLSET_LIST%) do (
  set FIELD_VALUE=%%i
  call :PROCESS_FIELD_VALUE
  set /A TOOLSET_LIST_INDEX+=1
)

pause

exit /b 0

:PROCESS_FIELD_VALUE
set /A TOOLSET_LIST_INDEX_REMAINDER=TOOLSET_LIST_INDEX %% 2

if %TOOLSET_LIST_INDEX_REMAINDER% EQU 0 (
  set "TOOLSET_ROOT_DIR=%FIELD_VALUE%"
  exit /b 0
)

set FIELD1_INDEX=1

:FIELD1_LOOP
set "FIELD1_VALUE="
for /F "eol= tokens=%FIELD1_INDEX% delims=|" %%i in (%FIELD_VALUE%) do set "FIELD1_VALUE=%%i"
if not defined FIELD1_VALUE exit /b 0

set "TOOLSET_BIN_ROOT=%TEST_ROOT%%TOOLSET_ROOT_DIR%/%FIELD1_VALUE%"
set "TOOLSET_BIN_ROOT=%TOOLSET_BIN_ROOT:/=\%"

call :TEST

set /A FIELD1_INDEX+=1

goto FIELD1_LOOP

:TEST
call :CMD "%%TOOLSET_BIN_ROOT%%\svn.exe" --version
exit /b 0

:CMD
echo.^>%*
rem run command and truncate the output
set IS_LAST_LINE_EMPTY=0
set LINE_STR_INDEX=0
for /F "usebackq delims=" %%i in (`@%* ^| findstr /B /N /R /C:".*"`) do (
  set LINE_STR=%%i
  call :PRINT && goto CMD_EXIT
  set /A LINE_STR_INDEX+=1
)

:CMD_EXIT
if %IS_LAST_LINE_EMPTY% EQU 0 echo.

exit /b 0

:PRINT
setlocal ENABLEDELAYEDEXPANSION

set LASTERROR=1
set OFFSET=0
:OFFSET_LOOP
set CHAR=!LINE_STR:~%OFFSET%,1!
if not "!CHAR!" == ":" ( set /A OFFSET+=1 && goto OFFSET_LOOP )
set /A OFFSET+=1

if "!LINE_STR:~%OFFSET%!" == "" set IS_LAST_LINE_EMPTY=1

set STOPSEQUENCE=!LINE_STR:~%OFFSET%,13!
if /i "!STOPSEQUENCE!" == "copyright (c)" (
  set LASTERROR=0
  goto PRINT_EXIT
)

echo.!LINE_STR:~%OFFSET%!

:PRINT_EXIT
(
  endlocal
  set IS_LAST_LINE_EMPTY=%IS_LAST_LINE_EMPTY%
  exit /b %LASTERROR%
)
