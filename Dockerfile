# Windows native container for Cake builds
# -----------------------------------------------------------------------
# PREREQUISITES (Docker Desktop):
#   1. Right-click tray icon → "Switch to Windows containers..."
#   2. Settings → General → UNCHECK "Use containerd for pulling and
#      storing images" → Apply & Restart
#      (The containerd/overlayfs snapshotter cannot handle the hard links
#       present in Windows base image layers.)
# -----------------------------------------------------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0-windowsservercore-ltsc2022

SHELL ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]

# Install Git directly — avoids Chocolatey, which creates Program Files
# hard links that break the containerd snapshotter on Docker Desktop.
# Pin the version; update the URL to upgrade.
ARG GIT_VERSION=2.44.0
ARG GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe

RUN Write-Host "Installing Git $env:GIT_VERSION ..."; \
    Invoke-WebRequest -Uri $env:GIT_URL -OutFile C:\git-setup.exe -UseBasicParsing; \
    Start-Process C:\git-setup.exe -ArgumentList '/VERYSILENT','/NORESTART','/NOCANCEL','/SP-','/CLOSEAPPLICATIONS','/RESTARTAPPLICATIONS','/COMPONENTS=icons,ext\reg\shellhere,assoc,assoc_sh' -Wait; \
    Remove-Item C:\git-setup.exe -Force; \
    Write-Host "Git installed."

# Add Git to the machine PATH
RUN $gitBin = 'C:\Program Files\Git\cmd'; \
    $cur = [Environment]::GetEnvironmentVariable('PATH', 'Machine'); \
    [Environment]::SetEnvironmentVariable('PATH', ($cur + ';' + $gitBin), 'Machine')

# Install Cake as a .NET global tool
RUN dotnet tool install --global Cake.Tool; \
    $toolPath = 'C:\Users\ContainerAdministrator\AppData\Roaming\dotnet\tools'; \
    $cur = [Environment]::GetEnvironmentVariable('PATH', 'Machine'); \
    [Environment]::SetEnvironmentVariable('PATH', ($cur + ';' + $toolPath), 'Machine')

# Switch back to cmd for smaller layer metadata overhead
SHELL ["cmd", "/S", "/C"]

# Working directory — mount your project here at runtime
WORKDIR C:/build

# Runtime configuration (override via -e / environment: in compose)
ENV CAKE_SCRIPT=build.cake
ENV CAKE_TARGET=Default
ENV CAKE_VERBOSITY=Normal

COPY entrypoint.ps1 C:/entrypoint.ps1

ENTRYPOINT ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "C:\\entrypoint.ps1"]
