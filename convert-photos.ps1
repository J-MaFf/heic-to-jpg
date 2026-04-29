param(
    [string]$FolderPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Failure {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
}

function Wait-ForExit {
    if ($env:HEIC_TO_JPG_NO_PAUSE -eq '1') {
        return
    }

    Write-Host
    Read-Host 'Press Enter to exit'
}

function Show-FfmpegInstallHelp {
    Write-Host
    Write-Warn 'ffmpeg was not found on PATH.'
    Write-Host 'Install ffmpeg, then run this script again.'
    Write-Host
    Write-Host 'Quick install options on Windows:'
    Write-Host '1) winget install --id Gyan.FFmpeg -e'
    Write-Host '2) choco install ffmpeg'
    Write-Host '3) Download a full build from https://ffmpeg.org/download.html'
    Write-Host
    Write-Host 'After install, open a new terminal and run: ffmpeg -version'
}

function Show-HeicSupportHelp {
    Write-Host
    Write-Warn 'ffmpeg is installed, but HEIC/HEIF support was not detected.'
    Write-Host 'Install a full ffmpeg build that includes HEIF/HEIC decoding support.'
    Write-Host
    Write-Host 'Try this command to inspect support:'
    Write-Host 'ffmpeg -hide_banner -demuxers | findstr /I "heic heif"'
    Write-Host
    Write-Host 'If no HEIC/HEIF entry appears, install a different ffmpeg build and retry.'
}

function Test-HeicSupport {
    param([string]$FfmpegPath)

    try {
        $demuxers = & $FfmpegPath -hide_banner -demuxers 2>&1 | Out-String
        $decoders = & $FfmpegPath -hide_banner -decoders 2>&1 | Out-String
        $codecs = & $FfmpegPath -hide_banner -codecs 2>&1 | Out-String
        $combined = "$demuxers`n$decoders`n$codecs"
        return ($combined -match '(?im)\bheic\b|\bheif\b')
    }
    catch {
        return $false
    }
}

function New-DesktopShortcut {
    param(
        [string]$TargetFolder,
        [string]$ShortcutName
    )

    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path -Path $desktop -ChildPath ("$ShortcutName.lnk")

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetFolder
    $shortcut.WorkingDirectory = $TargetFolder
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,3"
    $shortcut.Save()
}

function Get-UniqueOutputPath {
    param(
        [string]$Directory,
        [string]$BaseName,
        [string]$Extension
    )

    $candidate = Join-Path -Path $Directory -ChildPath ("$BaseName$Extension")
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $counter = 1
    while ($true) {
        $numbered = Join-Path -Path $Directory -ChildPath ("{0}_{1}{2}" -f $BaseName, $counter, $Extension)
        if (-not (Test-Path -LiteralPath $numbered)) {
            return $numbered
        }
        $counter++
    }
}

function Invoke-PhotoConversion {
    param(
        [string]$FolderPath
    )

    $defaultFolder = Join-Path -Path $env:USERPROFILE -ChildPath 'convert'
    $usingDefaultFolder = [string]::IsNullOrWhiteSpace($FolderPath)

    if ($usingDefaultFolder) {
        $targetFolder = $defaultFolder
    }
    else {
        try {
            $resolved = Resolve-Path -LiteralPath $FolderPath -ErrorAction Stop
            $targetFolder = $resolved.ProviderPath
        }
        catch {
            Write-Failure "The custom folder does not exist: $FolderPath"
            Wait-ForExit
            return 1
        }
    }

    if ($usingDefaultFolder -and -not (Test-Path -LiteralPath $targetFolder)) {
        Write-Info "Creating default folder: $targetFolder"
        New-Item -Path $targetFolder -ItemType Directory | Out-Null

        try {
            New-DesktopShortcut -TargetFolder $targetFolder -ShortcutName 'Convert Photos'
            Write-Success 'Created desktop shortcut: Convert Photos'
        }
        catch {
            Write-Warn "Could not create desktop shortcut. $_"
        }

        Write-Host
        Write-Info 'First-time setup complete.'
        Write-Host "Place your HEIC photos in: $targetFolder"
        Write-Host 'Then run this script again to start conversion.'
        Wait-ForExit
        return 0
    }

    if (-not (Test-Path -LiteralPath $targetFolder -PathType Container)) {
        Write-Failure "Folder not found: $targetFolder"
        Wait-ForExit
        return 1
    }

    $ffmpegCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if (-not $ffmpegCommand) {
        Show-FfmpegInstallHelp
        Wait-ForExit
        return 1
    }

    $ffmpegPath = $ffmpegCommand.Source
    if (-not (Test-HeicSupport -FfmpegPath $ffmpegPath)) {
        Show-HeicSupportHelp
        Wait-ForExit
        return 1
    }

    Write-Info "Scanning for HEIC files in: $targetFolder"

    $heicFiles = @(Get-ChildItem -Path $targetFolder -Recurse -File | Where-Object {
            $_.Extension -ieq '.heic'
        })

    if (-not $heicFiles -or $heicFiles.Count -eq 0) {
        Write-Warn 'No HEIC files found. Add files and run again.'
        Wait-ForExit
        return 0
    }

    $convertedCount = 0
    $skippedCount = 0
    $failedCount = 0
    $deletedCount = 0

    Write-Info ("Found {0} HEIC file(s). Starting conversion..." -f $heicFiles.Count)
    Write-Host

    foreach ($file in $heicFiles) {
        $directory = $file.DirectoryName
        $sourcePath = $file.FullName
        $baseOutputName = "{0}_converted" -f $file.BaseName
        $expectedOutput = Join-Path -Path $directory -ChildPath ("$baseOutputName.jpg")

        if (Test-Path -LiteralPath $expectedOutput) {
            Write-Warn "Skipping (already converted): $sourcePath"
            $skippedCount++
            continue
        }

        $outputPath = Get-UniqueOutputPath -Directory $directory -BaseName $baseOutputName -Extension '.jpg'

        Write-Info "Converting: $sourcePath"
        Write-Host "      -> $outputPath"

        try {
            & $ffmpegPath -hide_banner -loglevel error -i $sourcePath -q:v 2 $outputPath
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $outputPath)) {
                throw "ffmpeg exited with code $LASTEXITCODE"
            }

            $convertedCount++
            Write-Success "Converted: $outputPath"

            try {
                Remove-Item -LiteralPath $sourcePath -Force
                $deletedCount++
                Write-Success "Deleted original: $sourcePath"
            }
            catch {
                Write-Warn "Converted, but could not delete original: $sourcePath. $_"
            }
        }
        catch {
            $failedCount++
            Write-Failure "Failed: $sourcePath"
            Write-Host "       Reason: $_"
        }

        Write-Host
    }

    Write-Host 'Conversion complete.' -ForegroundColor Green
    Write-Host ("Converted: {0}" -f $convertedCount)
    Write-Host ("Skipped:   {0}" -f $skippedCount)
    Write-Host ("Failed:    {0}" -f $failedCount)
    Write-Host ("Deleted:   {0}" -f $deletedCount)

    Wait-ForExit
    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    $exitCode = Invoke-PhotoConversion -FolderPath $FolderPath
    exit $exitCode
}