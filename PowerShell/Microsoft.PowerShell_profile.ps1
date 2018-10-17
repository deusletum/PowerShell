function prompt {
    $p += $PWD.Path -replace '^[^:]+::', ''
    $p += "`r`n> "
    return $p
}

function Test-IsFileLocked {
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [ValidateScript({Test-Path -Path $_ -Leaf})]
        [string[]]$Path
    )

    foreach ($Item in $Path) {
        #Ensure this is a full path
        $Item = Convert-Path $Item
        #Verify that this is a file and not a directory

        Try {
            $FileStream = [System.IO.File]::Open($Item,'Open','Write')
            $FileStream.Close()
            $FileStream.Dispose()
            $IsLocked = $False
        } Catch [System.UnauthorizedAccessException] {
            $IsLocked = 'AccessDenied'
        } Catch {
            $IsLocked = $True
        }
        [pscustomobject]@{
            File = $Item
            IsLocked = $IsLocked
        }
    }
}

function New-FileEdit {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [ValidateScript({Test-Path -Path $_ -Leaf})]
        [string[]]$Path
    )
    $Path = Resolve-Path -Path $Path
    tf.exe edit $_
    c $_
}

function BuildXaml {
    Push-Location 'C:\Source\BuildTeam\Main\Source\Workflows\v10.0_2010\Imaging\Surface.TeamFoundation.Workflow.Imaging'
}

function GitSync {
    git fetch --all --recurse-submodules
}

function GitHardRest {
    #https://hdgtfs/tfs/Surface/Imaging/_git/ImagingCommon
    git reset --hard origin/master
}

function Tail {
    param (
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path -Path $_ -Leaf})]
        [string] $Path
    )
    Get-Content -path $Path -wait
}

function Get-ImagingBuildAgents {
    Get-TfsBuildAgent -CollectionUri "https://hdgtfs/tfs/surface" |
        Select-Object -ExpandProperty Agents |
        Where-Object {$_.MachineName -Match 'surfimgbld'} |
        Select-Object MachineName, IsReserved |
        Sort-Object -Property MachneName
}

function rr {
    Remove-Module -Name Imaging -Force | Out-Null
    Import-Module -Name Imaging | Out-Null
}
function Remove-ImagingTempFiles {
    $dirs = @("$RootDir\Logs\*", "$RootDir\Temp\*", "$RootDir\_Intermediate\*")
    Remove-Item -Path $Dirs -Recurse -Force -Verbose -ErrorAction SilentlyContinue
}

function New-AttestationRequest {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string] $DriverPath
    )

    $AutoSignPath = 'C:\AutoSign'
    $DriverPath = $(Resolve-Path -Path $DriverPath).Path
    Push-Location $AutoSignPath
    try {
        .\New-AttestSignDriver.ps1 -InputDir $DriverPath -OutputDir $DriverPath -CabDir C:\Drivers
    } finally {
        Pop-Location
    }
}

function Rel1 {
    $OrgPath = $env:Path
    C:\Source\Imaging\Rel1\Scripts\Env.ps1 -NoWelcome
    $env:Path = "$OrgPath;$($env:Path)"
}

function Main {
    $OrgPath = $env:Path
    C:\Source\Imaging\Main\Scripts\Env.ps1 -NoWelcome
    $env:Path = "$OrgPath;$($env:Path)"
}

function Dev {
    $OrgPath = $env:Path
    C:\Source\Imaging\Dev\Scripts\Env.ps1 -NoWelcome
    $env:Path = "$OrgPath;$($env:Path)"
}

function New-TFSCloak {
    $CloakPaths = Get-Contect -Path $UserDir\Cloak.txt
    $CloakPaths | ForEach-Oject {
        "Processing cloak:$_"
        tf.exe workfold /cloak "$_"
    }
}
function GetCertificateWithInfo {
    param(
        [Parameter(Mandatory=$true, Position = 0)]
        $CatalogFile
    )
    $SignerCertificate = $(Get-AuthenticodeSignature -FilePath $CatalogFile).SignerCertificate
    $Cert = $SignerCertificate.DnsNameList.Unicode
    $Issuer = $SignerCertificate.GetIssuerName()
    $EnhancedKeyUsageList = $SignerCertificate.EnhancedKeyUsageList.FriendlyName

    $isWHQLStyleCert = ($Cert -in @("Microsoft Windows Hardware Compatibility Publisher","Microsoft Windows Hardware Abstraction Layer Publisher"))
    $isPreProdCert   = $Issuer -eq "C=US, S=Washington, L=Redmond, O=Microsoft Corporation, CN=Microsoft Windows PCA 2010"
    $isAttestionSigned = (("Windows Hardware Driver Attested Verification" -in $EnhancedKeyUsageList) -or ($null -in $EnhancedKeyUsageList))

    $certInfo = [pscustomobject] @{
        PreProductionCert = $isPreProdCert
        WHQLStyleCert = $isWHQLStyleCert
        AttestationSigned = $isAttestionSigned
        Cert = $Cert
        Issuer = $Issuer
    }

    return $certInfo
}

function Resolve {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string] $Path
    )
    $CommandText = "tf.exe reconcile $Path /promote /adds /diff /deletes /noignore /recursive"
    Invoke-Expression -Command $CommandText
}

function Add {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string] $Path
    )
    Invoke-Expression -Command "tf add $Path /noignore /recursive"
}

function Get-CPUTemp {
    $CPUTemp = Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" | Select-Object -ExpandProperty CurrentTemperature
    $CPUTemp = $(((($CPUTemp/10)-273)*1.8)+32)
    Write-Output $CPUTemp
}

function Get-Cultures {
    [System.Globalization.CultureInfo]::GetCultures("AllCultures")
}

function Get-Tattoo {
    'All men must die and pass into oblivion'.ToCharArray() |
    ForEach-Object {"[char]$([int]$_)"} |
        ForEach-Object {
            $codestring += "$_,"
        }
    $MyTattoo = $codestring -replace '\[char\]110,\)\.ToString\(\)\}','[char]110).ToString()}'
    Write-Output '$' + $MyTattoo + '.ToString()}'
}

function Get-InfInfo  {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string] $file
    )

    $file = Resolve-Path -Path $file -Relative

    $regex = '(?mis)CatalogFile\=(?<Catfile>[\w\-]+\.cat)(.+)\[SourceDisksFiles\]\r\n'
    $regex += '(?<SourceDisksFiles>([\w_\-]+\.[\w_]+[\s\=]+[\w\,\\\-]+\r\n)+)'

    $InfString = $(Get-Content -Path $file | Out-String)
    $InfString -Match $regex

    $OutPut = [PSCustomObject] @{
        CatFileName = $($Matches['Catfile'])
        SourceDisksFiles = $($Matches['SourceDisksFiles'])
    }
    Write-Output $OutPut
}

function Enable-Hyperv {
    Get-WindowsOptionalFeature -Online |
    Where-Object FeatureName -Match 'Microsoft-Hyper-V-All' |
    Enable-WindowsOptionalFeature -Online -Verbose -NoRestart
}

function Get-MsgBox {
    param (
        [Parameter(Mandatory=$true)]
        [string] $msg,

        [Parameter(Mandatory=$true)]
        [string] $title
    )
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    $Result = [System.Windows.Forms.MessageBox]::Show($msg, $title,
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Warning,
    [System.Windows.Forms.MessageBoxDefaultButton]::Button2)
    Write-Output $Result
}

function Get-AllCerts {
    \\surface-build\DeploymentShare\ConfigureBuildMachine\Cert\Import-AllCerts.ps1
}

function New-TestSign {
    param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({$_ | ForEach-Object {Test-Path -Path $_}})]
        [string[]] $File
    )
    $File | ForEach-Object {
        $Inf = Get-ChildItem -Path $_
        if (-not($Inf.Extension -eq '.inf')) {
            Write-Host "$($Inf.Name) is not an inf"
            return
        }
        Push-Location $Inf.DirectoryName
        C:\Source\ProductBin\Jupiter\Tools\cert\sign_packages.cmd $($Inf.Name)
        Pop-Location
    }
}

function Test-DriverSymbols {
    Param(
        $Path = '.',
        $DropLocation
    )

    $symchkExe = 'C:\Source\Windows\RS2_RELEASE\15063.0.170317-1834\wdk\Tools\symchk.exe'
    if ($DropLocation) {
        $symbolPath = $DropLocation
    } else {
        $symbolPath = Join-Path -Path $Path -ChildPath '..\Symbols'
    }
    & $symchkExe $Path /sr $symbolPath /od /os
}

function Repair-TFSGit {
    \\desmo\wds\Software\hdgtfsgit\RepairTfsGit\RepairTfsGit.cmd
}

function Get-SubDirSize {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path -Path $_})]
        [string] $path
    )

    Get-ChildItem -Path $path -Directory |
    ForEach-Object {
        $Dir = $_
        $Name = Split-Path -Path $($Dir.FullName) -Leaf
        $Size = $null
        Get-ChildItem -Path $($Dir.FullName) -File -Recurse -ErrorAction SilentlyContinue |
        ForEach-Object {
            $File = $_
            $Size += $File.Length
        }
        if (($Size/1GB) -gt 1) {
            Write-Host "$Name size is $("{0:N2}" -f $($([math]::Round($Size,4,[MidPointRounding]::AwayFromZero))/1GB)) GB" -ForegroundColor DarkRed
        } elseif (($Size/1MB) -gt 1) {
            Write-Host "$Name size is $("{0:N2}" -f $($([math]::Round($Size,4,[MidPointRounding]::AwayFromZero))/1MB)) MB" -ForegroundColor DarkGreen
        } elseif (($Size/1KB) -gt 1) {
            Write-Host "$Name size is $("{0:N2}" -f $($([math]::Round($Size,4,[MidPointRounding]::AwayFromZero))/1KB)) KB" -ForegroundColor DarkCyan
        }
    }
}

Clear-Host
$Skull = @"
            .o oOOOOOOOo                                            OOOo
            Ob.OOOOOOOo  OOOo.      oOOo.                      .adOOOOOOO
            OboO"""""""""""".OOo. .oOOOOOo.    OOOo.oOOOOOo.."""""""""'OO
            OOP.oOOOOOOOOOOO "POOOOOOOOOOOo.   `"OOOOOOOOOP,OOOOOOOOOOOB'
            `O'OOOO'     `OOOOo"OOOOOOOOOOO` .adOOOOOOOOO"oOOO'    `OOOOo
            .OOOO'            `OOOOOOOOOOOOOOOOOOOOOOOOOO'            `OO
            OOOOO                 '"OOOOOOOOOOOOOOOO"`                oOO
            oOOOOOba.                .adOOOOOOOOOOba               .adOOOOo.
            oOOOOOOOOOOOOOba.    .adOOOOOOOOOO@^OOOOOOOba.     .adOOOOOOOOOOOO
            OOOOOOOOOOOOOOOOO.OOOOOOOOOOOOOO"`  '"OOOOOOOOOOOOO.OOOOOOOOOOOOOO
            "OOOO"       "YOoOOOOMOIONODOO"`  .   '"OOROAOPOEOOOoOY"     "OOO"
            Y           'OOOOOOOOOOOOOO: .oOOo. :OOOOOOOOOOO?'         :`
            :            .oO%OOOOOOOOOOo.OOOOOO.oOOOOOOOOOOOO?         .
            .            oOOP"%OOOOOOOOoOOOOOOO?oOOOOO?OOOO"OOo
                            '%o  OOOO"%OOOO%"%OOOOO"OOOOOO"OOO':
                                `$"  `OOOO' `O"Y ' `OOOO'  o             .
            .                  .     OP"          : o     .
                                        :
                                        .
"@

Write-Host $Skull -ForegroundColor DarkRed
Write-Host "Starting Imaging Build Environment`r`n" -ForegroundColor Cyan
New-Alias C "${env:ProgramFiles}\Microsoft VS Code\Code.exe" -Scope Global -Force
New-Alias CodeFlow "\\codeflow\public\cfLauncher.cmd" -Scope Global -Force
New-Alias bc "C:\BC4\BCompare.exe" -Scope Global -Force
New-Alias JI "${env:SystemRoot}\Just-install.exe" -Scope Global -Force