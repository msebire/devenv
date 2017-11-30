$kotlinRelease = "1.1.61"
$javaVersion = "8u152b1056.12"

$defaultToolsDriveLetter = 'T'
$defaultSourceDriveLetter = 'S'
$defaultCacheDriveLetter = 'Z'

$kotlinCompilerUrl = "https://github.com/JetBrains/kotlin/releases/download/v$kotlinRelease/kotlin-compiler-$kotlinRelease.zip"
$javaUrl = "https://bintray.com/jetbrains/intellij-jdk/download_file?file_path=jbsdk${javaVersion}_windows_x64.tar.gz"

$pathOri = $env:Path

function Expand-Archive($tarFile, $dest) {
    if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
        Install-Package -Scope CurrentUser -Force 7Zip4PowerShell > $null
    }
    Expand-7Zip $tarFile $dest
}


function Run-Elevated($command)
{
	Start-Process -FilePath powershell -Verb runas -Wait -WindowStyle Hidden -ArgumentList "-noprofile -command $Command"
}

Add-Type -assembly "system.io.compression.filesystem"


#$application = New-Object -ComObject Shell.Application
#$installPath = ($application.BrowseForFolder(0, 'Where todo you want to install the development environment ?', 0)).Self.Path
$installPath = $PSScriptRoot.Trim('\')

Write-Host "Development environment will be installed in " $installPath

$jreInstallPath = "$installPath\jre"
if (-not (Test-Path $jreInstallPath)) {
    Write-Host "Downloading Java version ${javaVersion}"
    Invoke-WebRequest -Uri "$javaUrl" -OutFile "${jreInstallPath}.tar.gz"
    Expand-Archive "${jreInstallPath}.tar.gz" "$installPath"
    Expand-Archive "${jreInstallPath}.tar" $jreInstallPath
    Remove-Item "${jreInstallPath}.tar.gz"
    Remove-Item "${jreInstallPath}.tar"
}

$kotlincInstallPath = "$installPath\kotlinc"
if (-not (Test-Path "$installPath\kotlinc")) {
    Write-Host "Downloading Kotlin Compiler $kotlinRelease"
    Invoke-WebRequest -Uri $kotlinCompilerUrl -OutFile "$installPath\kotlinc.zip"
    Expand-Archive "$installPath\kotlinc.zip" "$installPath"
    Remove-Item "$installPath\kotlinc.zip"
}

$toolsDriveLetter = if (($toolsDriveLetter = Read-Host "Tools drive [$defaultToolsDriveLetter]") -eq '') { $defaultToolsDriveLetter } else { $toolsDriveLetter }
$sourceDriveLetter = if (($sourceDriveLetter = Read-Host "Source drive [$defaultSourceDriveLetter]") -eq '') { $defaultSourceDriveLetter } else { $sourceDriveLetter }
$cacheDriveLetter = if (($cacheDriveLetter = Read-Host "Cache drive [$defaultCacheDriveLetter]") -eq '') { $defaultCacheDriveLetter } else { $cacheDriveLetter }

New-Item -ItemType Directory -Force -Path $installPath\${toolsDriveLetter}_drive | OUT-NULL
New-Item -ItemType Directory -Force -Path $installPath\${sourceDriveLetter}_drive | OUT-NULL
New-Item -ItemType Directory -Force -Path $installPath\${cacheDriveLetter}_drive | OUT-NULL

$env:DEVENV_TOOLS = "${toolsDriveLetter}:"
$env:DEVENV_SETTINGS = "${sourceDriveLetter}:\settings"
$env:DEVENV_HOME = "${sourceDriveLetter}:\sources"
$env:DEVENV_CACHE = "${cacheDriveLetter}:"


[Environment]::SetEnvironmentVariable("DEVENV_TOOLS", $env:DEVENV_TOOLS, "User")
[Environment]::SetEnvironmentVariable("DEVENV_SETTINGS", $env:DEVENV_SETTINGS, "User")
[Environment]::SetEnvironmentVariable("DEVENV_HOME", $env:DEVENV_HOME, "User")
[Environment]::SetEnvironmentVariable("DEVENV_CACHE", $env:DEVENV_CACHE, "User")


# mount for current session
Invoke-Expression "subst '${toolsDriveLetter}:' '$installPath\${toolsDriveLetter}_drive'" | Out-Null
Invoke-Expression "subst '${sourceDriveLetter}:' '$installPath\${sourceDriveLetter}_drive'" | Out-Null
Invoke-Expression "subst '${cacheDriveLetter}:' '$installPath\${cacheDriveLetter}_drive'" | Out-Null

# Permanent mount
$HKLM = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\DOS Devices"
#Run-Elevated "New-ItemProperty -Path '$HKLM' -Name '$toolsDriveLetter' -PropertyType String -Value '\??\$installPath\${toolsDriveLetter}_drive'"

# Create default folder
New-Item -ItemType Directory -Force -Path $env:DEVENV_SETTINGS | OUT-NULL
New-Item -ItemType Directory -Force -Path $env:DEVENV_HOME | OUT-NULL


Invoke-WebRequest -Uri "https://github.com/msebire/devenv/archive/master.zip" -OutFile "${env:DEVENV_CACHE}\devenv.zip"
Expand-Archive "${env:DEVENV_CACHE}\devenv.zip" "${env:DEVENV_CACHE}"

Copy-Item -Path "${env:DEVENV_CACHE}\devenv-master\init\tools\*" -Destination $env:DEVENV_TOOLS -Recurse


$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("${env:DEVENV_TOOLS}\Dev Console.lnk")
$Shortcut.TargetPath = "powershell"
$Shortcut.Arguments = "-NoProfile -NoLogo -NoExit -command %DEVENV_TOOLS%\bin\devenv.ps1"
$Shortcut.WorkingDirectory = "%DEVENV_HOME%"
$Shortcut.Save()

$env:Path = "$env:Path;$installPath\jre\bin;$installPath\kotlinc\bin;$env:DEVENV_TOOLS/bin"

Invoke-Expression "install kotlin"


Write-Host "Press any key to continue ..."
$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
$host.UI.RawUI.Flushinputbuffer()

$env:Path = $pathOri
