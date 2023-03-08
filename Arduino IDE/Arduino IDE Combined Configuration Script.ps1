$cliPath = "C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"
$configPath = "C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"
$localDataDir = "C:\Program Files\arduino-ide\Appdata\Local\Arduino15"
$localDownloadsDir = "C:\Program Files\arduino-ide\Appdata\Local\Arduino15\staging"
$userLibrariesDir = "$env:USERPROFILE\Documents\Arduino"
$batchFile = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/Arduino%20IDE.bat'
$yamlFile = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/arduino-cli.yaml'

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
