#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$appJson = "C:\Program Files\Docker\Docker\app.json"

# 1. Patch app.json — enable the Windows Containers component
Write-Host "Patching app.json..." -ForegroundColor Cyan
$json = Get-Content $appJson -Raw | ConvertFrom-Json

$comp = $json.components | Where-Object { $_.description -eq "Allow Windows Containers to be used with this installation" }
if (-not $comp) {
    Write-Error "Windows Containers component not found in app.json. Docker Desktop version may differ."
}
if ($comp.enabled -eq $true) {
    Write-Host "Already enabled in app.json." -ForegroundColor Green
} else {
    $comp.enabled = $true
    $json | ConvertTo-Json -Depth 10 | Set-Content $appJson -Encoding UTF8
    Write-Host "app.json patched." -ForegroundColor Green
}

# 2. Ensure the Containers Windows feature is enabled
Write-Host "Checking Containers Windows feature..." -ForegroundColor Cyan
$feature = Get-WindowsOptionalFeature -Online -FeatureName Containers
if ($feature.State -ne "Enabled") {
    Write-Host "Enabling Containers feature (reboot may be required)..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart
    Write-Host "Containers feature enabled. A reboot is required before continuing." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "Containers feature already enabled." -ForegroundColor Green
}

# 3. Restart Docker Desktop
Write-Host "Restarting Docker Desktop..." -ForegroundColor Cyan
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 3
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
Start-Sleep -Seconds 10

# 4. Switch to Windows containers
Write-Host "Switching to Windows containers..." -ForegroundColor Cyan
& "C:\Program Files\Docker\Docker\DockerCli.exe" -SwitchDaemon

Start-Sleep -Seconds 5
$mode = docker info --format "{{.OSType}}" 2>$null
Write-Host "Docker engine mode: $mode" -ForegroundColor $(if ($mode -eq "windows") { "Green" } else { "Red" })
