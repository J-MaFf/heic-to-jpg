Describe 'convert-photos integration behavior' {
  It 'returns 1 when custom folder does not exist' {
    $missingFolder = Join-Path $TestDrive 'missing-folder'
    $pwshPath = (Get-Command pwsh).Source
    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' -FolderPath $missingFolder | Out-Null
      $LASTEXITCODE | Should -Be 1
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
    }
  }

  It 'creates default convert folder on first run and exits 0' {
    $profilePath = Join-Path $TestDrive 'profile'
    $pwshPath = (Get-Command pwsh).Source
    New-Item -Path $profilePath -ItemType Directory | Out-Null

    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE
    $originalUserProfile = $env:USERPROFILE

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      $env:USERPROFILE = $profilePath

      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' | Out-Null

      $LASTEXITCODE | Should -Be 0
      (Test-Path -LiteralPath (Join-Path $profilePath 'convert')) | Should -BeTrue
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
      $env:USERPROFILE = $originalUserProfile
    }
  }

  It 'returns 1 when ffmpeg is not available on PATH' {
    $inputFolder = Join-Path $TestDrive 'no-ffmpeg'
    $pathWithoutFfmpeg = Join-Path $TestDrive 'empty-path'
    $pwshPath = (Get-Command pwsh).Source
    New-Item -Path $inputFolder -ItemType Directory | Out-Null
    New-Item -Path $pathWithoutFfmpeg -ItemType Directory | Out-Null

    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE
    $originalPath = $env:PATH

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      $env:PATH = $pathWithoutFfmpeg

      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' -FolderPath $inputFolder | Out-Null

      $LASTEXITCODE | Should -Be 1
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
      $env:PATH = $originalPath
    }
  }

  It 'returns 1 when ffmpeg exists but lacks HEIC support' {
    $inputFolder = Join-Path $TestDrive 'no-heic-support'
    $toolFolder = Join-Path $TestDrive 'tools-no-heic'
    $pwshPath = (Get-Command pwsh).Source
    New-Item -Path $inputFolder -ItemType Directory | Out-Null
    New-Item -Path $toolFolder -ItemType Directory | Out-Null
    Set-Content -LiteralPath (Join-Path $inputFolder 'sample.heic') -Value 'heic-data' -Encoding ASCII

    @'
@echo off
setlocal
if /I "%~1"=="-hide_banner" (
  if /I "%~2"=="-demuxers" (
    echo D  mov
    exit /b 0
  )
  if /I "%~2"=="-decoders" (
    echo V....D h264
    exit /b 0
  )
  if /I "%~2"=="-codecs" (
    echo DEVILS h264
    exit /b 0
  )
)
exit /b 1
'@ | Set-Content -LiteralPath (Join-Path $toolFolder 'ffmpeg.cmd') -Encoding ASCII

    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE
    $originalPath = $env:PATH

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      $env:PATH = "$toolFolder;$originalPath"

      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' -FolderPath $inputFolder | Out-Null

      $LASTEXITCODE | Should -Be 1
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
      $env:PATH = $originalPath
    }
  }

  It 'returns 0 when no HEIC files are found' {
    $inputFolder = Join-Path $TestDrive 'empty-input'
    $toolFolder = Join-Path $TestDrive 'tools-heic-empty'
    $pwshPath = (Get-Command pwsh).Source
    New-Item -Path $inputFolder -ItemType Directory | Out-Null
    New-Item -Path $toolFolder -ItemType Directory | Out-Null

    @'
@echo off
setlocal EnableDelayedExpansion
if /I "%~1"=="-hide_banner" (
  if /I "%~2"=="-demuxers" (
    echo D  heic
    exit /b 0
  )
  if /I "%~2"=="-decoders" (
    echo V....D hevc
    exit /b 0
  )
  if /I "%~2"=="-codecs" (
    echo DEVILS heic
    exit /b 0
  )
)
set "last="
:nextarg
if "%~1"=="" goto gotlast
set "last=%~1"
shift
goto nextarg
:gotlast
if "%last%"=="" exit /b 1
> "%last%" echo fake-jpg
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $toolFolder 'ffmpeg.cmd') -Encoding ASCII

    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE
    $originalPath = $env:PATH

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      $env:PATH = "$toolFolder;$originalPath"

      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' -FolderPath $inputFolder | Out-Null

      $LASTEXITCODE | Should -Be 0
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
      $env:PATH = $originalPath
    }
  }

  It 'converts HEIC files to JPG and deletes originals' {
    $inputFolder = Join-Path $TestDrive 'convert-success'
    $toolFolder = Join-Path $TestDrive 'tools-heic-convert'
    $pwshPath = (Get-Command pwsh).Source
    New-Item -Path $inputFolder -ItemType Directory | Out-Null
    New-Item -Path $toolFolder -ItemType Directory | Out-Null

    $source = Join-Path $inputFolder 'photo.heic'
    Set-Content -LiteralPath $source -Value 'heic-data' -Encoding ASCII

    @'
@echo off
setlocal EnableDelayedExpansion
if /I "%~1"=="-hide_banner" (
  if /I "%~2"=="-demuxers" (
    echo D  heic
    exit /b 0
  )
  if /I "%~2"=="-decoders" (
    echo V....D hevc
    exit /b 0
  )
  if /I "%~2"=="-codecs" (
    echo DEVILS heic
    exit /b 0
  )
)
set "last="
:nextarg
if "%~1"=="" goto gotlast
set "last=%~1"
shift
goto nextarg
:gotlast
if "%last%"=="" exit /b 1
> "%last%" echo fake-jpg
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $toolFolder 'ffmpeg.cmd') -Encoding ASCII

    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE
    $originalPath = $env:PATH

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      $env:PATH = "$toolFolder;$originalPath"

      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' -FolderPath $inputFolder | Out-Null

      $LASTEXITCODE | Should -Be 0
      (Test-Path -LiteralPath $source) | Should -BeFalse
      (Test-Path -LiteralPath (Join-Path $inputFolder 'photo_converted.jpg')) | Should -BeTrue
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
      $env:PATH = $originalPath
    }
  }

  It 'skips files already converted and keeps original HEIC' {
    $inputFolder = Join-Path $TestDrive 'skip-existing'
    $toolFolder = Join-Path $TestDrive 'tools-heic-skip'
    $pwshPath = (Get-Command pwsh).Source
    New-Item -Path $inputFolder -ItemType Directory | Out-Null
    New-Item -Path $toolFolder -ItemType Directory | Out-Null

    $source = Join-Path $inputFolder 'photo.heic'
    $expectedJpg = Join-Path $inputFolder 'photo_converted.jpg'
    Set-Content -LiteralPath $source -Value 'heic-data' -Encoding ASCII
    Set-Content -LiteralPath $expectedJpg -Value 'jpg-data' -Encoding ASCII

    @'
@echo off
setlocal EnableDelayedExpansion
if /I "%~1"=="-hide_banner" (
  if /I "%~2"=="-demuxers" (
    echo D  heic
    exit /b 0
  )
  if /I "%~2"=="-decoders" (
    echo V....D hevc
    exit /b 0
  )
  if /I "%~2"=="-codecs" (
    echo DEVILS heic
    exit /b 0
  )
)
set "last="
:nextarg
if "%~1"=="" goto gotlast
set "last=%~1"
shift
goto nextarg
:gotlast
if "%last%"=="" exit /b 1
> "%last%" echo fake-jpg
exit /b 0
'@ | Set-Content -LiteralPath (Join-Path $toolFolder 'ffmpeg.cmd') -Encoding ASCII

    $originalPause = $env:HEIC_TO_JPG_NO_PAUSE
    $originalPath = $env:PATH

    try {
      $env:HEIC_TO_JPG_NO_PAUSE = '1'
      $env:PATH = "$toolFolder;$originalPath"

      & $pwshPath -NoProfile -File 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1' -FolderPath $inputFolder | Out-Null

      $LASTEXITCODE | Should -Be 0
      (Test-Path -LiteralPath $source) | Should -BeTrue
      (Test-Path -LiteralPath $expectedJpg) | Should -BeTrue
      (Test-Path -LiteralPath (Join-Path $inputFolder 'photo_converted_1.jpg')) | Should -BeFalse
    }
    finally {
      $env:HEIC_TO_JPG_NO_PAUSE = $originalPause
      $env:PATH = $originalPath
    }
  }
}

Describe 'shortcut launcher definition' {
  BeforeAll {
    . 'C:\Users\jmaffiola\Documents\Scripts\heic-to-jpg\convert-photos.ps1'
  }

  It 'prefers a common pwsh install path for the launcher shortcut' {
    $originalProgramFiles = $env:ProgramFiles
    $originalLocalAppData = $env:LOCALAPPDATA

    try {
      $env:ProgramFiles = Join-Path $TestDrive 'Program Files'
      $env:LOCALAPPDATA = Join-Path $TestDrive 'LocalAppData'

      $pwshInstallPath = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
      New-Item -Path (Split-Path -Path $pwshInstallPath -Parent) -ItemType Directory -Force | Out-Null
      Set-Content -LiteralPath $pwshInstallPath -Value 'pwsh' -Encoding ASCII

      $definition = Get-ScriptLauncherShortcutDefinition -ScriptPath 'C:\Users\TestUser\Documents\Scripts\heic-to-jpg\convert-photos.ps1'

      $definition.ShortcutName | Should -Be 'Run Photo Converter'
      $definition.TargetPath | Should -Be $pwshInstallPath
      $definition.WorkingDirectory | Should -Be 'C:\Users\TestUser\Documents\Scripts\heic-to-jpg'
      $definition.Arguments | Should -Be '-NoProfile -ExecutionPolicy Bypass -File "C:\Users\TestUser\Documents\Scripts\heic-to-jpg\convert-photos.ps1"'
      $definition.IconLocation | Should -Be "$pwshInstallPath,0"
    }
    finally {
      $env:ProgramFiles = $originalProgramFiles
      $env:LOCALAPPDATA = $originalLocalAppData
    }
  }

  It 'falls back to Windows PowerShell when pwsh is unavailable' {
    $originalProgramFiles = $env:ProgramFiles
    $originalLocalAppData = $env:LOCALAPPDATA

    try {
      Mock Get-Command { $null } -ParameterFilter {
        $Name -eq 'pwsh' -and $CommandType -eq 'Application'
      }

      $env:ProgramFiles = Join-Path $TestDrive 'MissingProgramFiles'
      $env:LOCALAPPDATA = Join-Path $TestDrive 'MissingLocalAppData'

      $definition = Get-ScriptLauncherShortcutDefinition -ScriptPath 'C:\Users\TestUser\Documents\Scripts\heic-to-jpg\convert-photos.ps1'
      $fallbackPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

      $definition.TargetPath | Should -Be $fallbackPath
      $definition.IconLocation | Should -Be "$fallbackPath,0"
    }
    finally {
      $env:ProgramFiles = $originalProgramFiles
      $env:LOCALAPPDATA = $originalLocalAppData
    }
  }
}
