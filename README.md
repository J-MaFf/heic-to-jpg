# HEIC to JPG Photo Converter

Simple Windows PowerShell tool to batch-convert HEIC photos to JPG using ffmpeg.

## What It Does

- Scans a target folder and all subfolders for `.heic` files
- Converts each file to JPG with explicit quality (`-q:v 2`)
- Writes JPG files next to the originals
- Uses descriptive names like `photo_converted.jpg`
- Skips files when the expected converted JPG already exists
- Deletes original HEIC files after successful conversion
- Continues processing if one file fails

## Requirements

- Windows PowerShell 5.1+ or PowerShell 7+
- `ffmpeg` available on PATH

### Install ffmpeg (Windows)

Choose one:

1. `winget install --id Gyan.FFmpeg -e`
2. `choco install ffmpeg`
3. Download a full build from [ffmpeg.org](https://ffmpeg.org/download.html)

Verify install:

```powershell
ffmpeg -version
```

## Usage

### Default Folder Mode

Run:

```powershell
.\convert-photos.ps1
```

On first run, the script:

- Creates `C:\Users\<your-user>\convert` if missing
- Creates a desktop shortcut named `Convert Photos` to that folder
- Shows instructions to place photos in the folder
- Exits without converting (first-run setup behavior)

Run it again after adding HEIC files.

### Custom Folder Mode

```powershell
.\convert-photos.ps1 -FolderPath "C:\path\to\photos"
```

If the custom folder does not exist, the script exits with an error message.

## Conversion Output Rules

- `photo.heic` becomes `photo_converted.jpg`
- If `photo_converted.jpg` already exists, that source HEIC is treated as already converted and skipped
- If an output name collision happens for a new conversion, a numbered name is used (for example `photo_converted_1.jpg`)

## Troubleshooting

- If ffmpeg is missing, the script prints install instructions
- If ffmpeg appears installed but HEIC support is missing, the script prints HEIC-specific guidance
- If no HEIC files are found, the script reports that and exits cleanly

## Notes

- Converted JPG quality is controlled by ffmpeg `-q:v 2`
- The script pauses before exit so it is easy to run by double-click
