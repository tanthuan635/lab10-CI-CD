@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Build, test and deploy a React app on Windows.
rem Pipeline usage: deploy.bat [BUILD_DIR] [DEPLOY_DIR] [BACKUP_ROOT]
rem Freestyle usage: deploy.bat

set "SOURCE_ARG=%~1"
set "TARGET_ARG=%~2"
set "BACKUP_ARG=%~3"

if defined WORKSPACE (
    set "PROJECT_ROOT=%WORKSPACE%"
) else (
    for %%I in ("%~dp0..") do set "PROJECT_ROOT=%%~fI"
)

if defined SOURCE_ARG goto :source_ready

echo INFO: No pre-built directory supplied; running the complete CI build...
where node.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: node.exe is not available on PATH.
    exit /b 2
)
where npm.cmd >nul 2>&1
if errorlevel 1 (
    echo ERROR: npm.cmd is not available on PATH.
    exit /b 2
)
if not exist "%PROJECT_ROOT%\package-lock.json" (
    echo ERROR: package-lock.json is required for a repeatable npm ci build.
    exit /b 2
)

pushd "%PROJECT_ROOT%"
if errorlevel 1 (
    echo ERROR: Cannot enter project directory: "%PROJECT_ROOT%"
    exit /b 2
)

echo INFO: Installing dependencies...
call npm ci --no-audit --no-fund
if errorlevel 1 (
    popd
    echo ERROR: npm ci failed.
    exit /b 20
)

echo INFO: Running tests...
call npm test
if errorlevel 1 (
    popd
    echo ERROR: Tests failed; deployment was not changed.
    exit /b 21
)

echo INFO: Building the React application...
if not defined VITE_BUILD_VERSION set "VITE_BUILD_VERSION=%BUILD_NUMBER%"
if not defined VITE_BUILD_VERSION set "VITE_BUILD_VERSION=manual"
call npm run build
if errorlevel 1 (
    popd
    echo ERROR: React build failed; deployment was not changed.
    exit /b 22
)
popd

if exist "%PROJECT_ROOT%\build\index.html" set "SOURCE_ARG=%PROJECT_ROOT%\build"
if not defined SOURCE_ARG if exist "%PROJECT_ROOT%\dist\index.html" set "SOURCE_ARG=%PROJECT_ROOT%\dist"

:source_ready
if not defined TARGET_ARG set "TARGET_ARG=%DEPLOY_DIR%"
if not defined BACKUP_ARG set "BACKUP_ARG=%BACKUP_DIR%"
if not defined TARGET_ARG set "TARGET_ARG=C:\JenkinsDeploy\ReactApp"
if not defined BACKUP_ARG set "BACKUP_ARG=C:\JenkinsDeploy\Backups"

if not defined SOURCE_ARG goto :missing_source
if not defined TARGET_ARG goto :missing_target
if not defined BACKUP_ARG goto :missing_backup

for %%I in ("%SOURCE_ARG%") do set "SOURCE_DIR=%%~fI"
for %%I in ("%TARGET_ARG%") do set "TARGET_DIR=%%~fI"
for %%I in ("%BACKUP_ARG%") do set "BACKUP_ROOT=%%~fI"

if not exist "%SOURCE_DIR%\index.html" (
    echo ERROR: Build output is missing index.html: "%SOURCE_DIR%"
    exit /b 2
)

rem Validate all paths before using robocopy /MIR. In particular, never allow a
rem drive root or overlapping source, target, and backup trees.
set "DEPLOY_SOURCE_CANON=%SOURCE_DIR%"
set "DEPLOY_TARGET_CANON=%TARGET_DIR%"
set "DEPLOY_BACKUP_CANON=%BACKUP_ROOT%"
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command ^
  "$s=[IO.Path]::GetFullPath($env:DEPLOY_SOURCE_CANON).TrimEnd('\');" ^
  "$t=[IO.Path]::GetFullPath($env:DEPLOY_TARGET_CANON).TrimEnd('\');" ^
  "$b=[IO.Path]::GetFullPath($env:DEPLOY_BACKUP_CANON).TrimEnd('\');" ^
  "$c=[StringComparison]::OrdinalIgnoreCase;" ^
  "$inside={param($x,$parent) $x.StartsWith($parent.TrimEnd('\')+'\',$c)};" ^
  "if($s -eq [IO.Path]::GetPathRoot($s)){Write-Error 'BUILD_DIR cannot be a drive or share root.';exit 9};" ^
  "if($t -eq [IO.Path]::GetPathRoot($t)){Write-Error 'DEPLOY_DIR cannot be a drive or share root.';exit 10};" ^
  "if($b -eq [IO.Path]::GetPathRoot($b)){Write-Error 'BACKUP_DIR cannot be a drive or share root.';exit 11};" ^
  "if($s.Equals($t,$c) -or (&$inside $s $t) -or (&$inside $t $s)){Write-Error 'Build and deploy directories must not overlap.';exit 12};" ^
  "if($b.Equals($t,$c) -or (&$inside $b $t) -or (&$inside $t $b)){Write-Error 'Deploy and backup directories must not overlap.';exit 13};" ^
  "if($s.Equals($b,$c) -or (&$inside $s $b) -or (&$inside $b $s)){Write-Error 'Build and backup directories must not overlap.';exit 14}"
if errorlevel 1 (
    echo ERROR: Unsafe deployment path configuration. Nothing was copied.
    exit /b 3
)

where robocopy.exe >nul 2>&1
if errorlevel 1 (
    echo ERROR: robocopy.exe is required but was not found.
    exit /b 4
)

if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"
if errorlevel 1 (
    echo ERROR: Cannot create backup root: "%BACKUP_ROOT%"
    exit /b 5
)

for /f "usebackq delims=" %%T in (`powershell.exe -NoLogo -NoProfile -NonInteractive -Command "[DateTime]::UtcNow.ToString('yyyyMMdd_HHmmss_fff',[Globalization.CultureInfo]::InvariantCulture)"`) do set "TIMESTAMP=%%T"
if not defined TIMESTAMP (
    echo ERROR: Could not generate the UTC backup timestamp.
    exit /b 6
)
set "TIMESTAMP=%TIMESTAMP%Z"
set "BACKUP_DEST=%BACKUP_ROOT%\%TIMESTAMP%"

set "HAS_CURRENT=0"
if exist "%TARGET_DIR%" for /f "delims=" %%I in ('dir /b /a "%TARGET_DIR%" 2^>nul') do set "HAS_CURRENT=1"

if "%HAS_CURRENT%"=="1" goto :backup_current
echo INFO: No existing deployment to back up.
goto :copy_release

:backup_current
if exist "%BACKUP_DEST%" (
    echo ERROR: Backup destination already exists: "%BACKUP_DEST%"
    exit /b 7
)
mkdir "%BACKUP_DEST%"
if errorlevel 1 (
    echo ERROR: Cannot create backup destination: "%BACKUP_DEST%"
    exit /b 8
)

echo INFO: Backing up "%TARGET_DIR%" to "%BACKUP_DEST%"...
robocopy "%TARGET_DIR%" "%BACKUP_DEST%" /E /XJ /COPY:DAT /DCOPY:DAT /R:3 /W:2 /NP
set "BACKUP_RC=%ERRORLEVEL%"
if %BACKUP_RC% GEQ 8 (
    echo ERROR: Backup failed with robocopy exit code %BACKUP_RC%.
    exit /b %BACKUP_RC%
)
echo INFO: Backup completed with robocopy exit code %BACKUP_RC%.

:copy_release
if exist "%TARGET_DIR%" goto :target_ready
mkdir "%TARGET_DIR%"
if errorlevel 1 (
    echo ERROR: Cannot create deployment directory: "%TARGET_DIR%"
    exit /b 9
)

:target_ready

echo INFO: Deploying "%SOURCE_DIR%" to "%TARGET_DIR%"...
robocopy "%SOURCE_DIR%" "%TARGET_DIR%" /MIR /XJ /COPY:DAT /DCOPY:DAT /R:3 /W:2 /NP
set "DEPLOY_RC=%ERRORLEVEL%"
if %DEPLOY_RC% GEQ 8 (
    echo ERROR: Deployment failed with robocopy exit code %DEPLOY_RC%.
    if "%HAS_CURRENT%"=="1" echo INFO: The pre-deploy backup remains at "%BACKUP_DEST%".
    exit /b %DEPLOY_RC%
)

echo INFO: Deployment completed with robocopy exit code %DEPLOY_RC%.
if "%HAS_CURRENT%"=="1" echo INFO: Backup saved at "%BACKUP_DEST%".
exit /b 0

:missing_source
echo ERROR: BUILD_DIR was not supplied and neither dist nor build contains index.html.
echo Usage: %~nx0 [BUILD_DIR] [DEPLOY_DIR] [BACKUP_ROOT]
exit /b 2

:missing_target
echo ERROR: DEPLOY_DIR was not supplied as argument 2 or an environment variable.
echo Usage: %~nx0 [BUILD_DIR] [DEPLOY_DIR] [BACKUP_ROOT]
exit /b 2

:missing_backup
echo ERROR: BACKUP_DIR was not supplied as argument 3 or an environment variable.
echo Usage: %~nx0 [BUILD_DIR] [DEPLOY_DIR] [BACKUP_ROOT]
exit /b 2
