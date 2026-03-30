param()

$ErrorActionPreference = "Stop"

$CakeScript    = if ($null -ne $env:CAKE_SCRIPT)    { $env:CAKE_SCRIPT    } else { "build.cake" }
$CakeTarget    = if ($null -ne $env:CAKE_TARGET)    { $env:CAKE_TARGET    } else { "Default" }
$CakeVerbosity = if ($null -ne $env:CAKE_VERBOSITY) { $env:CAKE_VERBOSITY } else { "Normal" }

Write-Host "=== Cake Builder ===" -ForegroundColor Cyan
Write-Host "Working dir : $(Get-Location)"
Write-Host "Script      : $CakeScript"
Write-Host "Target      : $CakeTarget"
Write-Host "Verbosity   : $CakeVerbosity"
Write-Host ""

if (-not (Test-Path $CakeScript)) {
    Write-Error "Build script not found: $CakeScript`nMount your project to C:\build or set CAKE_SCRIPT."
    exit 1
}

# Restore local tools if a manifest exists (e.g. .config/dotnet-tools.json).
# This is a no-op when the project uses the globally installed Cake instead.
if (Test-Path ".config/dotnet-tools.json") {
    Write-Host "Restoring local .NET tools..." -ForegroundColor Cyan
    dotnet tool restore
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

dotnet cake $CakeScript --target=$CakeTarget --verbosity=$CakeVerbosity

exit $LASTEXITCODE
