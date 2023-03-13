$ArduinoIdePath = "C:\Program Files\arduino-ide"
$configFolderPath = "$ArduinoIdePath\Appdata"
$cliPath = "$ArduinoIdePath\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"

$batchFileUrl = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/Arduino%20IDE.bat'
$batchFilePath = 'C:\Program Files\arduino-ide\Arduino IDE.bat'

$yamlFileUrl = 'https://raw.githubusercontent.com/suhsdit/ImmyBot-Scripts/main/Arduino%20IDE/arduino-cli.yaml'
$yamlFilePath = "C:\Program Files\arduino-ide\Appdata\arduino-cli.yaml"

$certRootUrl = 'https://github.com/suhsdit/ImmyBot-Scripts/raw/main/Arduino%20IDE/certs/'
$certs = @(
    'adafruit.cer',
    'arduinollc.cer',
    'arduinosa.cer',
    'arduinosrl.cer'
)


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
            $coreBoardsInstalled -and
            !$originalShortcutExists -and
            $batchShortcutExists -and
            #firewall rules
            #$FirewallruleIn.Enabled -and $FirewallruleOut.Enabled -and
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

        # If the batch file does not exist, download it
        if (-not $batchShortcutExists) {
            Write-Host "Downloading batch file"
            Invoke-WebRequest -Uri $batchFileUrl -OutFile $batchFilePath
        }

        # If the shortcut to the batch file does not exist, create it using arduino ide icon
        if (-not $batchShortcutExists) {
            Write-Host "Creating shortcut to batch file"
            # Create a System.Drawing.Icon object from the executable file
            Add-Type -AssemblyName System.Drawing

            # Extract the associated icon from the executable file
            $icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$arduinoIdePath\Arduino IDE.exe")

            # Save icon
            $icon.Save("$arduinoIdePath\Arduino IDE.ico")

            # Create a WScript.Shell COM object
            $shell = New-Object -ComObject WScript.Shell

            # Get the shortcut object
            $shortcut = $shell.CreateShortcut("$env:PUBLIC\Desktop\Arduino-IDE.lnk")

            # Set the target path and arguments of the shortcut
            $shortcut.TargetPath = $batchFilePath

            # Set the icon location and index of the shortcut
            $shortcut.IconLocation = $icon.Location
            $shortcut.IconIndex = $icon.IconIndex

            # Save the shortcut changes
            $shortcut.Save()

            # Get shortcut target path of Arduino IDE.lnk
            




        # If inbound firewall rules are not created, create them
        if ($mdnsTCPFirewallruleIn -and $mdnsUDPFirewallruleIn -and $ArduinoTCPFirewallruleIn -and $ArduinoUDPFirewallruleIn) {
            Write-Host "Creating inbound firewall rules"
            New-NetFirewallRule -DisplayName "Arduino IDE TCP inbound" -Direction Inbound -Action Allow -Protocol TCP -Program "C:\Program Files\Arduino-ide\arduino ide.exe"
            New-NetFirewallRule -DisplayName "Arduino IDE UDP inbound" -Direction Inbound -Action Allow -Protocol UDP -Program "C:\Program Files\Arduino-ide\arduino ide.exe"
            New-NetFirewallRule -DisplayName "mdns-discovery UDP inbound" -Direction Inbound -Action Allow -Protocol UDP -Program "C:\program files\arduino-ide\appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.8\mdns-discovery.exe"
            New-NetFirewallRule -DisplayName "mdns-discovery TCP inbound" -Direction Inbound -Action Allow -Protocol TCP -Program "C:\program files\arduino-ide\appdata\local\arduino15\packages\builtin\tools\mdns-discovery\1.0.8\mdns-discovery.exe"        

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
