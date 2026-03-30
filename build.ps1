<#
.SYNOPSIS
    Helper script to build a project using the cake-builder container.

.PARAMETER ProjectDir
    Absolute path to the project directory containing build.cake.
    Defaults to the current directory.

.PARAMETER Target
    Cake target to run. Defaults to "Default".

.PARAMETER Script
    Cake build script filename. Defaults to "build.cake".

.PARAMETER Verbosity
    Cake output verbosity: Quiet | Minimal | Normal | Verbose | Diagnostic.
    Defaults to "Normal".

.PARAMETER Rebuild
    Force a rebuild of the Docker image before running.

.EXAMPLE
    .\build.ps1 -ProjectDir C:\repos\MyProject -Target Pack
#>
param(
    [string] $ProjectDir  = (Get-Location).Path,
    [string] $Target      = "Default",
    [string] $Script      = "build.cake",
    [string] $Verbosity   = "Normal",
    [switch] $Rebuild
)

$ErrorActionPreference = "Stop"

# Validate Docker is in Windows containers mode
$dockerInfo = docker info --format "{{.OSType}}" 2>$null
if ($dockerInfo -ne "windows") {
    Write-Error @"
Docker is currently in '$dockerInfo' mode.  Two steps required:

  1. Switch to Windows containers:
       Right-click the Docker Desktop tray icon → 'Switch to Windows containers...'

  2. Disable the containerd snapshotter (prevents hard-link errors in Windows layers):
       Docker Desktop → Settings → General
       UNCHECK 'Use containerd for pulling and storing images'
       Click 'Apply & Restart'
"@
    exit 1
}

# Warn if containerd snapshotter is active (causes hard-link failures in Windows layers)
$snapshotterInfo = docker info --format "{{.Driver}}" 2>$null
if ($snapshotterInfo -eq "overlayfs") {
    Write-Warning @"
Docker is using the containerd/overlayfs snapshotter.
Windows container builds may fail with hard-link errors.
Fix: Docker Desktop → Settings → General → uncheck 'Use containerd for pulling
and storing images' → Apply & Restart
"@
}

if (-not (Test-Path $ProjectDir)) {
    Write-Error "Project directory not found: $ProjectDir"
    exit 1
}

$imageTag = "cake-builder:latest"
$scriptDir = $PSScriptRoot

if ($Rebuild -or -not (docker image inspect $imageTag 2>$null)) {
    Write-Host "Building Docker image..." -ForegroundColor Cyan
    docker build -t $imageTag $scriptDir
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Running Cake build in container..." -ForegroundColor Cyan
Write-Host "  Project : $ProjectDir"
Write-Host "  Target  : $Target"
Write-Host "  Script  : $Script"
Write-Host ""

docker run --rm `
    -v "${ProjectDir}:C:\build" `
    -v "cake-nuget-cache:C:\Users\ContainerAdministrator\AppData\Roaming\NuGet" `
    -e "CAKE_SCRIPT=$Script" `
    -e "CAKE_TARGET=$Target" `
    -e "CAKE_VERBOSITY=$Verbosity" `
    $imageTag

exit $LASTEXITCODE
