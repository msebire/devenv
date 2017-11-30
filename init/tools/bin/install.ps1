PARAM(
    [Parameter(Mandatory=$true)][string] $application
)

Write-Host "Installing ${application}"

$root = "${env:DEVENV_CACHE}\devenv-master"

Remove-Item -Recurse -ErrorAction Ignore "${env:DEVENV_CACHE}/install/${application}" | OUT-NULL
New-Item -ItemType Directory -Force -Path "${env:DEVENV_CACHE}/install/${application}" | OUT-NULL

Invoke-Expression "kotlinc -script ${root}\tools\${application}\install.kts"
