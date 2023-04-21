$ArduinoIdePath = "C:\Program Files\arduino-ide"
$configFolderPath = "$ArduinoIdePath\Appdata"
$cliPath = "$ArduinoIdePath\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"

$batchFileUrl = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/Arduino%20IDE.bat'
$batchFilePath = 'C:\Program Files\arduino-ide\Arduino IDE.bat'
$shortcutFileUrl = 'https://github.com/suhsdit/ImmyBot-Scripts/raw/main/Arduino%20IDE/Arduino-IDE.lnk'

$yamlFileUrl = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/arduino-cli.yaml'
$yamlFilePath = "C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"

$certRootUrl = 'https://github.com/suhsdit/ImmyBot-Scripts/raw/main/Arduino%20IDE/certs/'
$certs = @(
    'adafruit.cer',
    'arduinollc.cer',
    'arduinosa.cer',
    'arduinosrl.cer'
)

function Get-ContentHash {
    param(
        [string]$Content
    )
    $hashAlgorithm = [System.Security.Cryptography.SHA256]::Create()
    $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
    $hashBytes = $hashAlgorithm.ComputeHash($contentBytes)
    return [System.BitConverter]::ToString($hashBytes).Replace("-", "")
}


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

    # Check if hash of yaml file on disk matches hash of yaml file on github
    $yamlFileHash = Get-FileHash $yamlFilePath -Algorithm SHA256
    Write-Host "Local File Hash: $($yamlFileHash.Hash)"
    $yamlFileContentFromUrl = Invoke-WebRequest -Uri $yamlFileUrl -UseBasicParsing | Select-Object -ExpandProperty Content
    $yamlFileHashFromUrl = Get-ContentHash -Content $yamlFileContentFromUrl
    Write-Host "Github File Hash: $yamlFileHashFromURL"
    $yamlFileMatch = $yamlFileHash.Hash -eq $yamlFileHashFromUrl
} else {
    Write-Host "X YAML file does not exist in config folder" -ForegroundColor Red
    
    # We'll say the hash match is true so we can download the file
    $yamlFileHash = $true
}

# Check if yaml file hash matches IF yaml file exists
if ($yamlFileMatch -and $configFileExists) {
    Write-Host "√ YAML file hash matches" -ForegroundColor Green
} else {
    Write-Host "X YAML file hash does not match" -ForegroundColor Red
}

# Check if core boards are installed using & $cliPath core list
$coreBoardsInstalled = & $cliPath core list  --config-file $yamlFilePath | Select-String -Pattern "arduino:avr"
if ($coreBoardsInstalled) {
    Write-Host "√ Core boards are installed" -ForegroundColor Green
} else {
    Write-Host "X Core boards are not installed" -ForegroundColor Red
}

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

# Check if start menu shortcut exists for Arduino IDE
$originalStartMenuShortcutExists = Test-Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Arduino IDE.lnk"
if ($originalStartMenuShortcutExists) {
    Write-Host "X Shortcut is not removed from start menu" -ForegroundColor Red
} else {
    Write-Host "√ Shortcut is removed from start menu" -ForegroundColor Green
}

# Check if start menu shortcut exists for Arduino IDE batch file
$batchStartMenuShortcutExists = Test-Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Arduino-IDE.lnk"
if ($batchStartMenuShortcutExists) {
    Write-Host "√ Shortcut to batch file exists in start menu" -ForegroundColor Green
} else {
    Write-Host "X Shortcut to batch file does not exist in start menu" -ForegroundColor Red
}


# Check firewall rules
$ArduinoUDPFirewallruleIn = (Get-NetFirewallRule -DisplayName "Arduino IDE UDP inbound").Enabled
$ArduinoTCPFirewallruleIn = (Get-NetFirewallRule -DisplayName "Arduino IDE TCP inbound").Enabled
$mdnsUDPFirewallruleIn = (Get-NetFirewallRule -DisplayName "mdns-discovery UDP inbound").Enabled
$mdnsTCPFirewallruleIn = (Get-NetFirewallRule -DisplayName "mdns-discovery TCP inbound").Enabled
if ($mdnsTCPFirewallruleIn -and $mdnsUDPFirewallruleIn -and $ArduinoTCPFirewallruleIn -and $ArduinoUDPFirewallruleIn) {
    Write-Host "√ Windows Defender Firewall rules exist" -ForegroundColor Green
} else {
    Write-Host "X Windows Defender Firewall rules do not exist" -ForegroundColor Red
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
            $yamlFileMatch -and
            $coreBoardsInstalled -and
            !$originalShortcutExists -and
            $batchShortcutExists -and
            !$originalStartMenuShortcutExists -and
            $batchStartMenuShortcutExists -and
            #firewall rules
            $ArduinoUDPFirewallruleIn -and $ArduinoTCPFirewallruleIn -and
            $mdnsUDPFirewallruleIn -and $mdnsTCPFirewallruleIn -and
            #certs
            $ArduinoSrlCert -and $ArduinoLlcCert -and $ArduinoSaCert -and $AdafruitCert
            ) {
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
            New-Item $configFolderPath -ItemType Directory -Force
            $acl = Get-Acl $configFolderPath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Modify","ContainerInherit,ObjectInherit","None","Allow")
            $acl.SetAccessRule($rule)
            Set-Acl $configFolderPath $acl
            attrib +h $configFolderPath
        }
        
        # If the yaml file does not exist, download it
        if (-not $configFileExists) {
            Write-Host "Downloading YAML file"
            Invoke-WebRequest -Uri $yamlFileUrl -OutFile $yamlFilePath
            $acl = Get-Acl $yamlFilePath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone","Modify","ContainerInherit,ObjectInherit","None","Allow")
            $acl.SetAccessRule($rule)
            Set-Acl $yamlFilePath $acl
            attrib +h $yamlFilePath
        }

        # If the yaml file does not match, replace it
        if (-not $yamlFileMatch) {
            Write-Host "Replacing YAML file"
            Remove-Item $yamlFilePath -Force
            Invoke-WebRequest -Uri $yamlFileUrl -OutFile $yamlFilePath
            $acl = Get-Acl $yamlFilePath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
            $acl.SetAccessRule($rule)
            Set-Acl $yamlFilePath $acl
            attrib +h $yamlFilePath
        }

        # If the core boards are not installed, install them
        if (-not $coreBoardsInstalled) {
            Write-Host "Installing core boards"
            & $cliPath core install arduino:avr --config-file $yamlFilePath
        }

        # If the original shortcut exists, delete it
        if ($originalShortcutExists) {
            Write-Host "Deleting original shortcut"
            Remove-Item "$env:PUBLIC\Desktop\Arduino IDE.lnk"
        }

        # If original start menu shortcut exists, delete it
        if ($originalStartMenuShortcutExists) {
            Write-Host "Deleting original start menu shortcut"
            Remove-Item "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Arduino IDE.lnk"
        }

        # If the batch file does not exist, download it
        if (-not $batchShortcutExists) {
            Write-Host "Downloading batch file"
            Invoke-WebRequest -Uri $batchFileUrl -OutFile $batchFilePath
        }

        # If Start Menu shortcut to the batch file does not exist, create it
        if (-not $batchStartMenuShortcutExists) {
            Write-Host "Creating shortcut to batch file in start menu"
            
            # download arduino ide shortcut from github
            Invoke-WebRequest -Uri $shortcutFileUrl -OutFile "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Arduino-IDE.lnk"
        }

        # If the shortcut to the batch file does not exist, create it
        if (-not $batchShortcutExists) {
            Write-Host "Creating shortcut to batch file"
            
            # download arduino ide shortcut from github
            Invoke-WebRequest -Uri $shortcutFileUrl -OutFile "$env:PUBLIC\Desktop\Arduino-IDE.lnk"
        }

        # If inbound firewall rules are not created, create them
        if (-not $mdnsTCPFirewallruleIn -and -not $mdnsUDPFirewallruleIn -and -not $ArduinoTCPFirewallruleIn -and -not $ArduinoUDPFirewallruleIn) {
            Write-Host "Creating inbound firewall rules"
            New-NetFirewallRule -DisplayName "Arduino IDE TCP inbound" -Direction Inbound -Action Allow -Protocol TCP -Program "C:\Program Files\Arduino-ide\arduino ide.exe"
            New-NetFirewallRule -DisplayName "Arduino IDE UDP inbound" -Direction Inbound -Action Allow -Protocol UDP -Program "C:\Program Files\Arduino-ide\arduino ide.exe"
            New-NetFirewallRule -DisplayName "mdns-discovery UDP inbound" -Direction Inbound -Action Allow -Protocol UDP -Program "C:\program files\arduino-ide\appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.8\mdns-discovery.exe"
            New-NetFirewallRule -DisplayName "mdns-discovery TCP inbound" -Direction Inbound -Action Allow -Protocol TCP -Program "C:\program files\arduino-ide\appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.8\mdns-discovery.exe"
        }

        # If certificates are not installed, install them
        if (-not $ArduinoSrlCert -and -not $ArduinoLlcCert -and -not $ArduinoSaCert -and -not $AdafruitCert) {
            # Copy certs from github to arduino\appdata
            Write-Host "Downloading certificates"
            $certPath = "C:\Program Files\arduino-ide\Appdata\certificates"
            New-Item $certPath -ItemType Directory -Force
            foreach ($cert in $certs) {
                $certurl = $CertRootUrl + $cert
                Write-Host "Downloading $certurl"
                Invoke-WebRequest -Uri $certurl -OutFile "$certPath\$cert" -verbose
            }

            # Install certs
            Write-Host "Installing certificates"
            foreach ($cert in $certs) {
                Write-Host "Installing $cert"
                certutil -addstore -f "TrustedPublisher" "$certPath\$cert"
            }
        }
        return
    }
    "get" {
        # You can return anything from here, used when in "Monitor" mode
        return
    }
}