$TestResult = $true

#Check if PixyMon v2 shortcut is on desktop
$PixyMonShortcut = Get-ChildItem -Path "C:\Users\Public\Desktop\PixyMon v2.lnk" -ErrorAction SilentlyContinue
if ($PixyMonShortcut) {
    # PixyMon v2 shortcut is on desktop
    Write-Host "PixyMon v2 shortcut is on desktop"
} else {
    # PixyMon v2 shortcut is not on desktop
    Write-Host "PixyMon v2 shortcut is not on desktop"
}

# Find all drivers installed on system
$PixyDrivers = Test-Path "C:\Windows\System32\DriverStore\FileRepository\pixy*"
if ($PixyDrivers) {
    # PixyMon v2 drivers are installed
    Write-Host "PixyMon v2 drivers are installed"
} else {
    # PixyMon v2 drivers are not installed
    Write-Host "PixyMon v2 drivers are not installed"
}

if ($PixyMonShortcut) {
    $TestResult = $false
    }


switch ($method) {
    "test" {
        # Used in Audit and Enforce Mode
        # You can output anything you want before this, but the last thing returned must be castable into a boolean (true or false)
        return $TestResult
    }
    "set" {
        if ($PixyMonShortcut) {
            Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PixyMon v2\PixyMon v2.lnk" -Destination "C:\Users\Public\Desktop\PixyMon v2.lnk"
        }

        # if drivers are not installed, install them
        if (!$PixyDrivers) {
            # Install PixyMon v2 drivers
            Write-Host "Installing PixyMon v2 drivers"
            pnputil /add-driver "C:\Program Files (x86)\PixyMon v2\driver\*.inf" /subdirs
        }
        return
    }
    "get" {
        # You can return anything from here, used when in "Monitor" mode
        return
    }
}
