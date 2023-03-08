Invoke-ImmyCommand -Timeout 600 -IncludeLocals {
$InstallerLogFile = [IO.Path]::GetTempFileName()
$Transforms = ""
if($LicenseFilePath -and (Test-Path $LicenseFilePath) -and $LicenseFilePath -like "*.mst")
{
    Write-Host "Applying $LicenseFilePath as MSI Transform"
    $Transforms = "TRANSFORMS=`"$LicenseFilePath`""
}
$Arguments = @"
/c msiexec /i "$InstallerFile" /qn /norestart /l "$InstallerLogFile" REBOOT=REALLYSUPPRESS ALLUSERS=1 $Transforms
"@
Write-Host "InstallerLogFile: $InstallerLogFile"
$Process = Start-Process -Wait cmd -ArgumentList $Arguments -Passthru
Write-Host "Exit Code: $($Process.ExitCode)";
switch ($Process.ExitCode)
{
    0 { Write-Host "Success" }
    3010 { Write-Host "Success. Reboot required to complete installation" }
    1641 { Write-Host "Success. Installer has initiated a reboot" }
    default {
        Write-Host "Exit code does not indicate success"
        Get-Content $InstallerLogFile -ErrorAction SilentlyContinue | select -Last 50
    }
}
}