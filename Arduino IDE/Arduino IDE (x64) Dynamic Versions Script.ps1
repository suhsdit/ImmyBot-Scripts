Get-DynamicVersionsFromGitHubUrl `
    -GitHubReleasesUrl 'https://github.com/arduino/arduino-ide/releases' `
    -VersionsPattern "arduino-ide_(?<Version>[\d\.]+)_Windows_64bit.msi"