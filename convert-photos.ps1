param(
    [string]$FolderPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:ThisScriptPath = $PSCommandPath

<#
.SYNOPSIS
Writes an informational status message.

.PARAMETER Message
The message text to display.
#>
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

<#
.SYNOPSIS
Writes a success status message.

.PARAMETER Message
The message text to display.
#>
function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

<#
.SYNOPSIS
Writes a warning status message.

.PARAMETER Message
The message text to display.
#>
function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

<#
.SYNOPSIS
Writes an error status message.

.PARAMETER Message
The message text to display.
#>
function Write-Failure {
    param([string]$Message)
    Write-Host "[ERR]  $Message" -ForegroundColor Red
}

<#
.SYNOPSIS
Pauses before exit unless automation has disabled prompts.
#>
function Wait-ForExit {
    if ($env:HEIC_TO_JPG_NO_PAUSE -eq '1') {
        return
    }

    Write-Host
    Read-Host 'Press Enter to exit'
}

<#
.SYNOPSIS
Shows installation guidance when ffmpeg is missing from PATH.
#>
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

<#
.SYNOPSIS
Shows troubleshooting guidance when ffmpeg cannot decode HEIC files.

.PARAMETER SampleHeicPath
The sample HEIC file used for the decode probe.
#>
function Show-HeicSupportHelp {
    param([string]$SampleHeicPath)

    Write-Host
    Write-Warn 'ffmpeg is installed, but HEIC/HEIF support was not detected.'
    Write-Host 'A real decode probe failed for the sample HEIC input.'

    if (-not [string]::IsNullOrWhiteSpace($SampleHeicPath)) {
        Write-Host "Probe file: $SampleHeicPath"
    }

    Write-Host 'Install a full ffmpeg build that includes HEIF/HEIC decoding support.'
    Write-Host
    Write-Host 'Try this command to manually test decoding:'
    if (-not [string]::IsNullOrWhiteSpace($SampleHeicPath)) {
        Write-Host ("ffmpeg -hide_banner -loglevel error -i `"{0}`" -frames:v 1 -f null NUL" -f $SampleHeicPath)
    }
    else {
        Write-Host 'ffmpeg -hide_banner -loglevel error -i "<your-file>.heic" -frames:v 1 -f null NUL'
    }
    Write-Host
    Write-Host 'If this command fails, install a different ffmpeg build and retry.'
}

<#
.SYNOPSIS
Tests whether the installed ffmpeg build can decode a HEIC file.

.PARAMETER FfmpegPath
The full path to the ffmpeg executable.

.PARAMETER SampleHeicPath
The HEIC file used for the decode probe.
#>
function Test-HeicSupport {
    param(
        [string]$FfmpegPath,
        [string]$SampleHeicPath
    )

    if ([string]::IsNullOrWhiteSpace($SampleHeicPath) -or -not (Test-Path -LiteralPath $SampleHeicPath -PathType Leaf)) {
        return $false
    }

    try {
        # Real decode probe: try decoding one frame from an actual HEIC source.
        & $FfmpegPath -hide_banner -loglevel error -i $SampleHeicPath -frames:v 1 -f null NUL 2>&1 | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

<#
.SYNOPSIS
Builds the full desktop shortcut path for a shortcut name.

.PARAMETER ShortcutName
The shortcut name without the .lnk extension.
#>
function Get-DesktopShortcutPath {
    param([string]$ShortcutName)

    $desktop = [Environment]::GetFolderPath('Desktop')
    return Join-Path -Path $desktop -ChildPath ("$ShortcutName.lnk")
}

<#
.SYNOPSIS
Creates or updates a desktop shortcut.

.PARAMETER ShortcutName
The shortcut name without the .lnk extension.

.PARAMETER TargetPath
The executable or folder the shortcut should open.

.PARAMETER WorkingDirectory
The working directory assigned to the shortcut.

.PARAMETER Arguments
Optional command-line arguments for the shortcut target.

.PARAMETER IconLocation
Optional icon resource path for the shortcut.
#>
function New-DesktopShortcut {
    param(
        [string]$ShortcutName,
        [string]$TargetPath,
        [string]$WorkingDirectory,
        [string]$Arguments,
        [string]$IconLocation
    )

    $shortcutPath = Get-DesktopShortcutPath -ShortcutName $ShortcutName

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = $WorkingDirectory

    if (-not [string]::IsNullOrWhiteSpace($Arguments)) {
        $shortcut.Arguments = $Arguments
    }

    if (-not [string]::IsNullOrWhiteSpace($IconLocation)) {
        $shortcut.IconLocation = $IconLocation
    }

    $shortcut.Save()
}

<#
.SYNOPSIS
Finds the best PowerShell executable to use for the launcher shortcut.
#>
function Get-PreferredPowerShellPath {
    $fallbackPath = Join-Path -Path $env:SystemRoot -ChildPath 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $candidatePaths = @(
        (Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell\7\pwsh.exe'),
        (Join-Path -Path $env:ProgramFiles -ChildPath 'PowerShell\7-preview\pwsh.exe')
    )

    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        $candidatePaths += Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\WindowsApps\pwsh.exe'
    }

    $pwshCommand = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue
    if ($pwshCommand) {
        $candidatePaths += $pwshCommand.Source
    }

    $preferredPath = $candidatePaths |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } |
    Select-Object -Unique |
    Select-Object -First 1

    if (-not [string]::IsNullOrWhiteSpace($preferredPath)) {
        return $preferredPath
    }

    return $fallbackPath
}

<#
.SYNOPSIS
Builds the shortcut definition used to launch this script from the desktop.

.PARAMETER ScriptPath
The full path to the script file.
#>
function Get-ScriptLauncherShortcutDefinition {
    param([string]$ScriptPath)

    $launcherPath = Get-PreferredPowerShellPath
    $scriptDirectory = Split-Path -Path $ScriptPath -Parent

    return @{
        ShortcutName     = 'Run Photo Converter'
        TargetPath       = $launcherPath
        WorkingDirectory = $scriptDirectory
        Arguments        = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        IconLocation     = "$launcherPath,0"
    }
}

<#
.SYNOPSIS
Creates or refreshes the desktop shortcut that launches this script.

.PARAMETER ScriptPath
The full path to the script file.
#>
function Set-ScriptLauncherShortcut {
    param([string]$ScriptPath)

    $definition = Get-ScriptLauncherShortcutDefinition -ScriptPath $ScriptPath
    New-DesktopShortcut @definition
}

<#
.SYNOPSIS
Returns a non-conflicting output path for a converted image.

.PARAMETER Directory
The directory where the output file should be created.

.PARAMETER BaseName
The base file name without an extension.

.PARAMETER Extension
The file extension to append to the generated name.
#>
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

<#
.SYNOPSIS
Runs the HEIC-to-JPG conversion workflow for the target folder.

.PARAMETER FolderPath
An optional folder to process. When omitted, the default convert folder under the user profile is used.
#>
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
            New-DesktopShortcut -ShortcutName 'Convert Photos' -TargetPath $targetFolder -WorkingDirectory $targetFolder -IconLocation "$env:SystemRoot\System32\shell32.dll,3"
            Write-Success 'Created desktop shortcut: Convert Photos'
        }
        catch {
            Write-Warn "Could not create desktop shortcut. $_"
        }

        try {
            Set-ScriptLauncherShortcut -ScriptPath $script:ThisScriptPath
            Write-Success 'Created desktop shortcut: Run Photo Converter'
        }
        catch {
            Write-Warn "Could not create script shortcut. $_"
        }

        Write-Host
        Write-Info 'First-time setup complete.'
        Write-Host "Place your HEIC photos in: $targetFolder"
        Write-Host 'Then run this script again to start conversion.'
        Wait-ForExit
        return 0
    }

    if ($usingDefaultFolder) {
        try {
            Set-ScriptLauncherShortcut -ScriptPath $script:ThisScriptPath
        }
        catch {
            Write-Warn "Could not create script shortcut. $_"
        }
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

    Write-Info "Scanning for HEIC files in: $targetFolder"

    $heicFiles = @(Get-ChildItem -Path $targetFolder -Recurse -File | Where-Object {
            $_.Extension -ieq '.heic'
        })

    if (-not $heicFiles -or $heicFiles.Count -eq 0) {
        Write-Warn 'No HEIC files found. Add files and run again.'
        Wait-ForExit
        return 0
    }

    $ffmpegPath = $ffmpegCommand.Source
    $probeFile = $heicFiles[0].FullName
    if (-not (Test-HeicSupport -FfmpegPath $ffmpegPath -SampleHeicPath $probeFile)) {
        Show-HeicSupportHelp -SampleHeicPath $probeFile
        Wait-ForExit
        return 1
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