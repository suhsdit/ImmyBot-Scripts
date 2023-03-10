$configFolderPath = "C:\Program Files\arduino-ide\Appdata"
$cliPath = "C:\Program Files\arduino-ide\resources\app\node_modules\arduino-ide-extension\build\arduino-cli.exe"

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
$coreBoardsInstalled = & $cliPath core list | Select-String -Pattern "arduino:avr"
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

# Check firewall rule for Arduino IDE UDP inbound
$ArduinoUDPFirewallruleIn = Get-NetFirewallRule -DisplayName "Arduino IDE UDP inbound"
if ($ArduinoUDPFirewallruleIn.Enabled) {
    Write-Host "√ Windows Defender Firewall allows Arduino IDE UDP inbound" -ForegroundColor Green
} else {
    Write-Host "X Windows Defender Firewall does not allow Arduino IDE UDP inbound" -ForegroundColor Red
}

# Check firewall rule for Arduino IDE TCP inbound
$ArduinoTCPFirewallruleIn = Get-NetFirewallRule -DisplayName "Arduino IDE TCP inbound"
if ($ArduinoTCPFirewallruleIn.Enabled) {
    Write-Host "√ Windows Defender Firewall allows Arduino IDE TCP inbound" -ForegroundColor Green
} else {
    Write-Host "X Windows Defender Firewall does not allow Arduino IDE TCP inbound" -ForegroundColor Red
}

# Check firewall rule for mdns-discovery UDP inbound
$mdnsUDPFirewallruleIn = Get-NetFirewallRule -DisplayName "mdns-discovery UDP inbound"
if ($mdnsUDPFirewallruleIn.Enabled) {
    Write-Host "√ Windows Defender Firewall allows mdns-discovery UDP inbound" -ForegroundColor Green
} else {
    Write-Host "X Windows Defender Firewall does not allow mdns-discovery UDP inbound" -ForegroundColor Red
}

# Check firewall rule for mdns-discovery UDP inbound
$mdnsTCPFirewallruleIn = Get-NetFirewallRule -DisplayName "mdns-discovery TCP inbound"
if ($mdnsTCPFirewallruleIn.Enabled) {
    Write-Host "√ Windows Defender Firewall allows mdns-discovery TCP inbound" -ForegroundColor Green
} else {
    Write-Host "X Windows Defender Firewall does not allow mdns-discovery TCP inbound" -ForegroundColor Red
}

# Check if certificate is installed
# $ArduinoSrlCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Arduino SRL*"}
# $ArduinoLlcCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Arduino LLC*"}
# $ArduinoSaCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Arduino SA*"}
# $AdafruitCert = Get-ChildItem -Path Cert:\LocalMachine\TrustedPublisher | Where-Object {$_.Subject -like "*Adafruit*"}
# if ($ArduinoSrlCert -and $ArduinoLlcCert -and $ArduinoSaCert -and $AdafruitCert) {
#     Write-Host "√ Arduino certificates are installed" -ForegroundColor Green
# } else {
#     Write-Host "X Arduino certificates are not installed" -ForegroundColor Red
# }


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
            $FirewallruleIn.Enabled -and $FirewallruleOut.Enabled -and
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
            $wshShell = New-Object -ComObject WScript.Shell
            $shortcut = $wshShell.CreateShortcut("$env:PUBLIC\Desktop\Arduino-IDE.lnk")
            $shortcut.TargetPath = $batchFilePath
            $shortcut.IconLocation = "C:\Program Files\arduino-ide\resources\app\static\icons\arduino.ico"
            $shortcut.Save()
        }

        # If inbound tcp/udp Firewall rules are not created for Arduino IDE and mdns, create them for each exe
        # if (-not $ArduinoUDPFirewallruleIn.Enabled -and -not $ArduinoTCPFirewallruleIn.Enabled) {
        #     Write-Host "Creating inbound and outbound firewall rules for Arduino IDE"
        #     New-NetFirewallRule -DisplayName "Arduino IDE UDP inbound" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 5000 -Program "C:\Program Files\Arduino-ide\arduino ide.exe"
        #     New-NetFirewallRule -DisplayName "Arduino IDE TCP inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5000 -Program "C:\Program Files\Arduino-ide\arduino ide.exe"
        # }

        # if (-not $mdnsUDPFirewallruleIn.Enabled -and -not $mdnsTCPFirewallruleIn.Enabled) {
        #     Write-Host "Creating inbound firewall rules for mdns-discovery"
        #     #New-NetFirewallRule -DisplayName "mdns-discovery UDP inbound" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 5353 -Program "$($cliPath.Replace('arduino-cli.exe', 'mdns-discovery.exe'))"
        #     #New-NetFirewallRule -DisplayName "mdns-discovery TCP inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5353 -Program "$($cliPath.Replace('arduino-cli.exe', 'mdns-discovery.exe'))"
        # }

        

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
