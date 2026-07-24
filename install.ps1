# =====================================
# Steam Root File Deployment Script
# =====================================

# -------- Configuration ---------------

$GitHubRawBase = "https://raw.githubusercontent.com/USERNAME/steam-deploy/main"

$ZipUrl = "$GitHubRawBase/OST.zip"

# Files that should exist in the Steam ROOT folder
$RequiredFiles = @(
    "OpenSteamTool.dll",
    "xinput1_4.dll",
    "dwmapi.dll"
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
    exit 1

}



Write-Host "Steam found:"
Write-Host $SteamPath



# --------------------------------------
# Check existing files
# --------------------------------------

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



if ($Installed) {

    Write-Host ""
    Write-Host "All files already exist."
    Write-Host "Nothing to download."

    exit 0

}



# --------------------------------------
# Download ZIP
# --------------------------------------

$TempZip = Join-Path `
    $env:TEMP `
    "steam-deploy.zip"


Write-Host ""
Write-Host "Downloading files..."


Invoke-WebRequest `
    -Uri $ZipUrl `
    -OutFile $TempZip



if (!(Test-Path $TempZip)) {

    Write-Host "Download failed."
    exit 1

}



# --------------------------------------
# Extract into Steam root
# --------------------------------------

Write-Host "Installing files..."


Expand-Archive `
    -Path $TempZip `
    -DestinationPath $SteamPath `
    -Force



Remove-Item `
    $TempZip `
    -Force



Write-Host ""
Write-Host "Installation complete."