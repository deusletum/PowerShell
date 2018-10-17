# TODO add requires admin
# TODO add logging- probably should find a standard powershell logging package
# TODO add path checking
# TODO investigate using const vars in powershell
# TODO Conside creating an Object/Type with all the Const vars
# TODO Turn all this into functions

$rootDir = $PSScriptRoot
$ExtensionsFile = "$rootDir\vscode-extensions.txt"
$VSCodePath = "${env:ProgramFiles}\Microsoft VS Code\code.exe"
$VSCodeUserSettingsFilePath = "$env:USERPROFILE\AppData\Roaming\Code\User\Settings.json"
$JustInstallPath = "${env:SystemRoot}\System32\Just-Install.exe"
$MSIExecPath = "${env:SystemRoot}\System32\msiexec.exe"
$NodeJSPath = "${env:USERPROFILE}\AppData\Roaming\npm"
$NodePackages = @('install', 'typescript', 'electron', 'graphql', 'react', 'react-dom', 'react-router', 'redux', 'express', '-g')

# Install Just-Install to install VSCode
"Installing Just-Install package manger" | Write-Host -ForegroundColor DarkCyan
Start-Process -FilePath $MSIExecPath -ArgumentList @('/i','https://stable.just-install.it','/qn') -NoNewWindow -Wait
if ($LASTEXITCODE -ne 0) {
    "Just-Install Install Failed with exit code:$LASTEXITCODE" | Write-Error
}

"Updating Just-Install local package cache" | Write-Host -ForegroundColor DarkCyan
Start-Process -FilePath $JustInstallPath -ArgumentList @('Update') -NoNewWindow -Wait
if ($LASTEXITCODE -ne 0) {
    "Just-Install Update Failed with exit code:$LASTEXITCODE" | Write-Error
}

"Installing Git" | Write-Host -ForegroundColor DarkCyan
Start-Process -FilePath $JustInstallPath -ArgumentList @('install','git') -NoNewWindow -Wait
if ($LASTEXITCODE -ne 0) {
    "Just-Install Failed to install Git with exit code:$LASTEXITCODE" | Write-Error
}

"Installing NodeJS" | Write-Host -ForegroundColor DarkCyan
Start-Process -FilePath $JustInstallPath -ArgumentList @('install','node') -NoNewWindow -Wait
if ($LASTEXITCODE -ne 0) {
    "Just-Install Failed to install NodeJS with exit code:$LASTEXITCODE" | Write-Error
}

"Installing NodeJS Modules" | Write-Host -ForegroundColor DarkCyan
Start-Process -FilePath $NodeJSPath -ArgumentList @($NodePackages) -NoNewWindow -Wait
if ($LASTEXITCODE -ne 0) {
    "Npm Failed to install NodeJS modules with exit code:$LASTEXITCODE" | Write-Error
}

"Installing Visual Studio Code" | Write-Host -ForegroundColor DarkCyan
Start-Process -FilePath $JustInstallPath -ArgumentList @('install','visual-studio-code') -NoNewWindow -Wait
if ($LASTEXITCODE -ne 0) {
    "Just-Install Update Failed with exit code:$LASTEXITCODE" | Write-Error
}

"Installing Visual Studio Code Extensions from`r`n$Extensions" | Write-Host -ForegroundColor DarkCyan
Get-Content -Path $ExtensionsFile | ForEach-Object {
    Start-Process -FilePath $VSCodePath -ArgumentList @('--install-extension',$_) -NoNewWindow -Wait
    if ($LASTEXITCODE -ne 0) {
        "Failed Installing Visual Studio Code Extension:$_ with exit code" | Write-Warning
    }
}

"Copy User Settings.json file to`r`n$VSCodeUserSettingsFilePath"
Copy-Item -Path "$rootDir\Settings.json" -Destination $VSCodeUserSettingsFilePath -Force
if ($LASTEXITCODE -ne 0) {
    "Just-Install Update Failed with exit code:$LASTEXITCODE" | Write-Waring
}
