# =====================================
# Steam Root File Deployment Script
# =====================================

# -------- Configuration ---------------

$GitHubRawBase = "https://raw.githubusercontent.com/Goofert42/ost-install/main"

$ZipFileName = "OST-1.1.zip"
$ZipUrl = "$GitHubRawBase/$ZipFileName"

$VersionMatch = [regex]::Match(
    $ZipFileName,
    '^OST-(?<Version>[^.]+(?:\.[^.]+)*)\.zip$'
)

if (-not $VersionMatch.Success) {

    throw "The OST archive name '$ZipFileName' does not match the expected OST-{version}.zip format."

}

$ExpectedVersion = $VersionMatch.Groups["Version"].Value

# Files that should exist in the Steam ROOT folder
$RequiredFiles = @(
    "OpenSteamTool.dll",
    "xinput1_4.dll",
    "dwmapi.dll",
    "ost-version.txt"
)

# --------------------------------------


Write-Host "Searching for Steam installation..."


# Common Steam locations
$SteamLocations = @(
    "${env:ProgramFiles(x86)}\Steam",
    "${env:ProgramFiles}\Steam"
)


$SteamPath = $null


foreach ($Path in $SteamLocations) {

    if (Test-Path $Path) {

        $SteamPath = $Path
        break

    }

}


if (-not $SteamPath) {

    Write-Host "Steam folder not found."
    exit 0

}


Write-Host "Steam found:"
Write-Host $SteamPath


# --------------------------------------
# Check existing files BEFORE closing Steam
# --------------------------------------

Write-Host ""
Write-Host "Checking existing files..."


$Installed = $true


foreach ($File in $RequiredFiles) {

    $FullPath = Join-Path `
        $SteamPath `
        $File


    if (!(Test-Path $FullPath)) {

        $Installed = $false
        break

    }

}

$VersionFile = Join-Path $SteamPath "ost-version.txt"
$InstalledVersion = $null

if (Test-Path $VersionFile) {

    $InstalledVersion = (Get-Content $VersionFile -Raw).Trim()

}

if ($InstalledVersion -ne $ExpectedVersion) {

    $Installed = $false

}

if ($Installed) {

    Write-Host ""
    Write-Host "All files already exist."
    Write-Host "No changes required."
    exit 0

}


# --------------------------------------
# Files need updating - close Steam
# --------------------------------------

Write-Host ""
Write-Host "Changes required. Closing Steam..."


$SteamExe = Join-Path $SteamPath "Steam.exe"


if (Test-Path $SteamExe) {

    Start-Process $SteamExe "-shutdown"

}


# Wait for Steam to close

$Timeout = 30
$Elapsed = 0


while ($Elapsed -lt $Timeout) {

    $SteamRunning = Get-Process |
        Where-Object {
            $_.ProcessName -like "steam*"
        }


    if (-not $SteamRunning) {

        break

    }


    Write-Host "Waiting for Steam to close..."

    Start-Sleep -Seconds 2

    $Elapsed += 2

}



# Force close if still running

$SteamRunning = Get-Process |
    Where-Object {
        $_.ProcessName -like "steam*"
    }


if ($SteamRunning) {

    Write-Host "Steam did not close. Forcing shutdown..."

    $SteamRunning | Stop-Process -Force

}



# --------------------------------------
# Download and install
# --------------------------------------

$TempZip = Join-Path `
    $env:TEMP `
    $ZipFileName


Write-Host ""
Write-Host "Downloading files..."


Invoke-WebRequest `
    -Uri $ZipUrl `
    -OutFile $TempZip



Write-Host "Installing files..."


Expand-Archive `
    -Path $TempZip `
    -DestinationPath $SteamPath `
    -Force


Remove-Item `
    $TempZip `
    -Force

Set-Content `
    -Path $VersionFile `
    -Value $ExpectedVersion `
    -NoNewline



# --------------------------------------
# Restart Steam
# --------------------------------------

Write-Host ""
Write-Host "Starting Steam..."


if (Test-Path $SteamExe) {

    Start-Process $SteamExe

}


Write-Host "Finished."