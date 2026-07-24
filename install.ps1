# =====================================
# Steam Root File Deployment Script
# =====================================

# -------- Configuration ---------------

$GitHubRawBase = "https://raw.githubusercontent.com/Goofert42/ost-install/main"

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
    exit 0

}


Write-Host "Steam found:"
Write-Host $SteamPath


# --------------------------------------
# Close Steam
# --------------------------------------

Write-Host ""
Write-Host "Closing Steam..."


$SteamProcesses = @(
    "steam",
    "steamwebhelper"
)


foreach ($Process in $SteamProcesses) {

    Get-Process $Process -ErrorAction SilentlyContinue |
        Stop-Process -Force

}


# Wait until Steam fully exits

Start-Sleep -Seconds 3


while (Get-Process steam -ErrorAction SilentlyContinue) {

    Write-Host "Waiting for Steam to close..."
    Start-Sleep -Seconds 2

}



# --------------------------------------
# Check existing files
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



if ($Installed) {

    Write-Host ""
    Write-Host "All files already exist."
    Write-Host "Nothing to install."

}
else {


    # ----------------------------------
    # Download ZIP
    # ----------------------------------

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

    }
    else {


        # ------------------------------
        # Extract
        # ------------------------------

        Write-Host "Installing files..."


        Expand-Archive `
            -Path $TempZip `
            -DestinationPath $SteamPath `
            -Force



        Remove-Item `
            $TempZip `
            -Force



        Write-Host "Installation complete."

    }

}



# --------------------------------------
# Restart Steam
# --------------------------------------

Write-Host ""
Write-Host "Starting Steam..."


$SteamExe = Join-Path `
    $SteamPath `
    "Steam.exe"


if (Test-Path $SteamExe) {

    Start-Process $SteamExe

}
else {

    Write-Host "Steam.exe not found. Please start Steam manually."

}


Write-Host ""
Write-Host "Finished."