# docker-cake-builder

A self-contained Windows Docker image that runs [Cake](https://cakebuild.net/) builds without requiring any local .NET SDK or Cake installation. Mount your project directory and Cake runs inside the container.

## What it does

- Builds a Windows Server Core image with the .NET 8 SDK and `dotnet cake` installed as a global tool.
- Mounts your project folder into the container at `C:\build`.
- Reads `build.cake` (or a script you specify) and executes a Cake target.
- Persists the NuGet package cache in a named Docker volume (`cake-nuget-cache`) so subsequent builds don't re-download packages.

## Prerequisites

- Docker Desktop switched to **Windows containers**
  - Right-click the tray icon → *Switch to Windows containers...*
- Containerd snapshotter **disabled** (prevents hard-link errors in Windows layers)
  - Docker Desktop → Settings → General → uncheck *Use containerd for pulling and storing images* → Apply & Restart

## Quick start

```powershell
cd docker-cake-builder

# First run — builds the image, then runs the build
.\build.ps1 -ProjectDir C:\path\to\your\project

# Force a Docker image rebuild
.\build.ps1 -ProjectDir C:\path\to\your\project -Rebuild

# Run a specific Cake target
.\build.ps1 -ProjectDir C:\path\to\your\project -Target Pack

# Change verbosity
.\build.ps1 -ProjectDir C:\path\to\your\project -Verbosity Diagnostic
```

`-ProjectDir` defaults to the current directory, so if you're already inside your project you can just run `.\build.ps1`.

## Parameters

| Parameter | Default | Description |
| ----------- | --------- | ------------- |
| `-ProjectDir` | current directory | Absolute path to the folder containing `build.cake` |
| `-Target` | `Default` | Cake target to run |
| `-Script` | `build.cake` | Cake script filename relative to `-ProjectDir` |
| `-Verbosity` | `Normal` | `Quiet` \| `Minimal` \| `Normal` \| `Verbose` \| `Diagnostic` |
| `-Rebuild` | off | Force a rebuild of the Docker image before running |

## Using docker-compose

```powershell
$env:PROJECT_DIR = "C:\path\to\your\project"
docker-compose up --build
```

Override any variable inline:

```powershell
$env:CAKE_TARGET = "Pack"; $env:PROJECT_DIR = "C:\path\to\your\project"
docker-compose up
```

## Project layout expected

Your project needs a Cake script at its root (default: `build.cake`). Example minimal script:

```csharp
var target = Argument("target", "Default");

Task("Default")
    .Does(() => Information("Hello from Cake!"));

RunTarget(target);
```

## NuGet cache

The named volume `cake-nuget-cache` persists across runs. To clear it:

```powershell
docker volume rm cake-nuget-cache
```
