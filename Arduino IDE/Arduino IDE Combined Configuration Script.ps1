$cliPath = "C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"
$localDataDir = "C:\Program Files\arduino-ide\Appdata\Local\Arduino15"
$localDownloadsDir = "C:\Program Files\arduino-ide\Appdata\Local\Arduino15\staging"
$userLibrariesDir = "C:\ProgramData\Arduino\libraries"

$configFolderPath = "C:\Program Files\arduino-ide\Appdata"

$batchFileUrl = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/Arduino%20IDE.bat'
$batchFilePath = 'C:\Program Files\arduino-ide\Arduino IDE.bat'

$yamlFileUrl = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/arduino-cli.yaml'
$yamlFilePath = "C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"

$certpath = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/certs/'


#Test if config folder exists with proper permissions
$configFolderExists = Test-Path $configFolderPath
if ($configFolderExists) {
    Write-Host "√ Config folder exists" -ForegroundColor Green
} else {
    Write-Host "X Config folder does not exist" -ForegroundColor Red
}

# Test if yaml file exists in config folder
$configFileExists = Test-Path $yamlFilePath
if ($configFileExists) {
    Write-Host "√ YAML file exists in config folder" -ForegroundColor Green
} else {
    Write-Host "X YAML file does not exist in config folder" -ForegroundColor Red
}

# Check if core boards are installed
# $coreBoardsInstalled = & $cliPath core list | Select-String -Pattern "arduino:avr"
# $output = & $cliPath core list
# Write-Host "Output of core list:`n$output"
# if ($coreBoardsInstalled) {
#     Write-Host "Core boards installed"
# } else {
#     Write-Host "Core boards not installed"
# }

# Check if shortcut lnk exists on public desktop
$originalShortcutExists = Test-Path "$env:PUBLIC\Desktop\Arduino IDE.lnk"
if ($originalShortcutExists) {
    Write-Host "X Shortcut is not removed from public desktop" -ForegroundColor Red
} else {
    Write-Host "√ Shortcut is removed from public desktop" -ForegroundColor Green
}

# Check if shortcut to batch file exists on public desktop
$batchShortcutExists = Test-Path "$env:PUBLIC\Desktop\Arduino-IDE.lnk"
if ($batchShortcutExists) {
    Write-Host "√ Shortcut to batch file exists on public desktop" -ForegroundColor Green
} else {
    Write-Host "X Shortcut to batch file does not exist on public desktop" -ForegroundColor Red
}

# Check if firewall rules are in place
$FirewallRuleIn = Get-NetFirewallRule -DisplayName "arduino-cli.exe"
$FirewallRuleOut = Get-NetFirewallRule -DisplayName "arduino-cli.exe"
if ($FirewallRuleIn.Enabled -and $FirewallRuleOut.Enabled) {
    Write-Host "√ Windows Defender Firewall allows arduino-cli.exe to access the internet" -ForegroundColor Green
} else {
    Write-Host "X Windows Defender Firewall does not allow arduino-cli.exe to access the internet" -ForegroundColor Red
}

# Check if certificate is installed
$ArduinoSrlCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Arduino SRL*"}
$ArduinoLlcCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Arduino LLC*"}
$ArduinoSaCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Arduino SA*"}
$AdafruitCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Adafruit*"}
if ($ArduinoSrlCert -and $ArduinoLlcCert -and $ArduinoSaCert -and $AdafruitCert) {
    Write-Host "√ Arduino certificates are installed" -ForegroundColor Green
} else {
    Write-Host "X Arduino certificates are not installed" -ForegroundColor Red
}


switch ($method) {
    "test" {
        # Used in Audit and Enforce Mode
        # You can output anything you want before this, but the last thing returned must be castable into a boolean (true or false)

        # For each of the checks above, if the test fails, return false
        if ($configFolderExists -and
            $configFileExists -and
            $coreBoardsInstalled -and
            !$originalShortcutExists -and
            $batchShortcutExists -and
            $Firewallrule) {
            Write-Host "√ All checks passed" -ForegroundColor Green
            return $true
        } else {
            Write-Host "X One or more checks failed"  -ForegroundColor Red
            return $false
        }
    }
    "set" {
        # Perform action that will make the test return true the next time it runs

        # If the config folder does not exist, create it and set permissions
        if (-not $configFolderExists) {
            Write-Host "Creating config folder"
            $folderPath = "C:\Program Files\arduino-ide\Appdata"
            New-Item $folderPath -ItemType Directory -Force
            icacls $folderPath /grant Everyone:(OI)(CI)M
            attrib +h $folderPath
        }

        # If the yaml file does not exist, download it
        if (-not $configFileExists) {
            Write-Host "Downloading YAML file"
            Invoke-WebRequest -Uri $yamlFileUrl -OutFile $yamlFilePath
            icacls $yamlFilePath /grant Everyone:(OI)(CI)M
            attrib +h $yamlFilePath
        }

        # If the core boards are not installed, install them
        if (-not $coreBoardsInstalled) {
            Write-Host "Installing core boards"
            start-process -FilePath $cliPath -ArgumentList "core install arduino:avr --config-file $yamlFilePath" -Wait
        }

        # If the original shortcut exists, delete it
        if ($originalShortcutExists) {
            Write-Host "Deleting original shortcut"
            Remove-Item "$env:PUBLIC\Desktop\Arduino IDE.lnk"
        }

        # If the batch file does not exist, download it
        if (-not $batchShortcutExists) {
            Write-Host "Downloading batch file"
            Invoke-WebRequest -Uri $batchFileUrl -OutFile $batchFilePath
        }

        # If the shortcut to the batch file does not exist, create it using arduino ide icon
        if (-not $batchShortcutExists) {
            Write-Host "Creating shortcut to batch file"
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut("$env:PUBLIC\Desktop\Arduino-IDE.lnk")
            $shortcut.TargetPath = $batchFilePath
            $shortcut.IconLocation = "C:\Program Files\arduino-ide\resources\app\static\icons\arduino.ico"
            $shortcut.Save()
        }

        # If Firewall rules are not in place, create them
        if (-not $FirewallRuleIn.Enabled -and -not $FirewallRuleOut.Enabled) {
            Write-Host "Creating firewall rule"
            New-NetFirewallRule -DisplayName "arduino-cli.exe" -Direction Inbound -Action Allow -Program "$cliPath" -Enabled True
            New-NetFirewallRule -DisplayName "arduino-cli.exe" -Direction Outbound -Action Allow -Program "$cliPath" -Enabled True
        }

        # If certificates are not installed, install them


        

        
        return
    }
    "get" {
        # You can return anything from here, used when in "Monitor" mode
        return
    }
}
