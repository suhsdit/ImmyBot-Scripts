<# 
Default Inno Setup Install Script
 Inno setup contains a [Run] block that the packager may have inadvertently not skipped if silent
 Therefore Inno setups have a tendency to hang forever because they launch the application in the system context
 This should be fixed with the RegexActions below which will capture the name of the file it runs and terminate it, thus preventing the hang
#> 
$Arguments = @"
/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LOG="$InstallerLogFile"
"@
$Output = Start-ProcessWithLogTail $InstallerFile -ArgumentList $Arguments -LogFilePath $InstallerLogFile -RegexActions @{
    '\d\s+Filename: (.*.exe)' = {
        Write-Host "Hit Filename.exe!"
        try
        {
            $FileName = Split-Path -Leaf $matches[1]
        } catch
        {
            $FileName = $null
        }
        if($FileName)
        {
            Write-Host "Killing $FileName"
            taskkill /im $FileName /f
            Write-Host "Done"
        }
    }
    '\d\s+Log closed'={
        Write-Host "Hit Log Closed!"
        taskkill /im TrayTipAgentE.exe /f
    }
    '\d\s+Message box'={
        Write-Host "Hit Message Box!"
        try
        {
            Write-Host "Try on Message Box"
            $FileName = "pixy*"
            Write-Host "File name is $FileName"
        } catch
        {
            Write-Host "Catch on Message Box"
            $FileName = $null
        }
        if($FileName)
        {
            Write-Host "Killing $FileName"
            taskkill /im $FileName /f
            Write-Host "Done"
        }
    }
}

Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PixyMon v2\PixyMon v2.lnk" -Destination "C:\Users\Public\Desktop\PixyMon v2.lnk"