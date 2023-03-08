$cliPath = "C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"
$configPath = "C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"
$localDataDir = "C:\Program Files\arduino-ide\Appdata\Local\Arduino15"
$localDownloadsDir = "C:\Program Files\arduino-ide\Appdata\Local\Arduino15\staging"
$userLibrariesDir = "$env:USERPROFILE\Documents\Arduino"

$batchFile = @"
@echo off
setlocal

set "CONFIG_NAME=arduino-cli.yaml"
set "ARDUINO_CLI=C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"
set "APPDATALOCAL_DIR=C:\Program Files\arduino-ide\Appdata"
set "CONFIG_USER_DIR=%userprofile%\.arduinoIDE"
set "CONFIG_USER_FILE=%CONFIG_USER_DIR%\%CONFIG_NAME%"
set "CONFIG_BLANK_FILE=%APPDATALOCAL_DIR%\%CONFIG_NAME%"

if not exist "%CONFIG_USER_DIR%" mkdir "%CONFIG_USER_DIR%"
if not exist "%CONFIG_USER_FILE%" xcopy /I /Q /H /R /K /Y /S /E "%CONFIG_BLANK_FILE%" "%CONFIG_USER_DIR%"
attrib +h "%CONFIG_USER_DIR%"

"%ARDUINO_CLI%" config set directories.data      "%APPDATALOCAL_DIR%\Local\Arduino15"         --config-file "%CONFIG_USER_FILE%" "%ARDUINO_CLI%" config set directories.downloads "%APPDATALOCAL_DIR%\Local\Arduino15\staging" --config-file "%CONFIG_USER_FILE%"
start "" "C:\Program Files\arduino-ide\Arduino IDE.exe"

exit /b 0
"@

function Test-ArduinoConfig {
    # Test if the Arduino IDE is properly configured for each user on startup
    $configUserFile = "$env:USERPROFILE\.arduinoIDE\arduino-cli.yaml"
    $configBlankFile = "C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"

    if (!(Test-Path $configUserFile)) {
        return $false
    }

    $configUser = Get-Content $configUserFile
    $configBlank = Get-Content $configBlankFile

    if ($configUser -notcontains "directories.data: $localDataDir") {
        return $false
    }

    if ($configUser -notcontains "directories.downloads: $localDownloadsDir") {
        return $false
    }

    if (!(Test-Path $userLibrariesDir)) {
        return $false
    }

    return $true
}

function Set-ArduinoConfig {
     # Create and configure hidden folder for Arduino CLI config
     $folderPath = "C:\Program Files\arduino-ide\Appdata"
     New-Item $folderPath -ItemType Directory -Force
     Copy-Item "Appdata\arduino-cli.yaml" -Destination $folderPath -Force
     icacls $folderPath /grant Everyone:(OI)(CI)M
     attrib +h $folderPath

     # Install core boards using configuration file
     & $cliPath core install arduino:avr --config-file $configPath

     # Configure IDE for each user on startup
     $batchPath = "$env:ProgramFiles\arduino-ide\arduino-startup.bat"

     New-Item $batchPath -ItemType File -Force $batchFile | Out-File -FilePath $batchPath -Encoding ascii

     & $batchPath
 }

switch ($method) {
    "test" {
        # Used in Audit and Enforce Mode
        # You can output anything you want before this, but the last thing returned must be castable into a boolean (true or false)
        Test-ArduinoConfig
    }
    "set" {
        # Perform action that will make the test return true the next time it runs
        Set-ArduinoConfig

        return
    }
    "get" {
        # You can return anything from here, used when in "Monitor" mode
        return
    }
}
