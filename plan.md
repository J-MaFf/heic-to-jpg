# Photo Conversion Tool - SRS

## Problem Statement

User needs a simple, user-friendly tool to batch convert HEIC image files to JPG format on-demand. The conversion should be accessible via a double-click shortcut without requiring technical knowledge.

## Proposed Solution

Create a PowerShell script (`convert-photos.ps1`) that:

1. Detects the "convert" folder automatically (checks `C:\Users\<username>\convert`) or accepts a custom folder as a parameter
2. If using default folder and it doesn't exist, creates the folder and a desktop shortcut named `Convert Photos` to it
3. Prompts user to place HEIC photos in the convert folder only if the folder was just created, then exits
4. Locates all HEIC files in the designated folder and its subfolders
5. Converts each HEIC file to JPG format using ffmpeg with an explicit JPG quality setting
6. Saves converted files alongside the source files while preserving subfolder structure
7. Uses descriptive output naming and skips files that have already been converted
8. Deletes original HEIC files after successful conversion
9. Provides user-friendly status messages and error handling
10. Displays ffmpeg installation instructions if ffmpeg is not available or if the installed build lacks HEIC support

## Requirements

### Functional Requirements

1. **File Input**: Scan designated "convert" folder and its subfolders for all `.heic` and `.HEIC` files
2. **Conversion**: Convert each HEIC file to JPG using ffmpeg with an explicit quality setting
3. **File Output**: Save converted JPG files in the same folder as source HEIC files, preserving subfolder structure
4. **Naming**: Convert `photo.heic` → `photo_converted.jpg` (preserve original filename, add descriptive suffix, change extension)
5. **Duplicate Filename Handling**: If a descriptive output name already exists for a different source, append a number to the output filename (e.g., `photo_converted_1.jpg`, `photo_converted_2.jpg`)
6. **Already Converted Handling**: If the expected converted JPG already exists for a source HEIC file, skip that file and report it as already converted
7. **File Deletion**: Delete original HEIC files after successful conversion
8. **Folder Creation & Setup**: If using default folder (no parameter):
   - Create `C:\Users\<username>\convert` folder if it doesn't exist

- Create a desktop shortcut named `Convert Photos` pointing to the convert folder
- Display instructions guiding user to place photos in the folder (only on first run when folder is created)
- Exit after setup so the user can add photos before processing

9. **Error Handling**: Gracefully handle cases where:
   - No HEIC files are found in the folder
   - ffmpeg is not available on PATH (display installation instructions)

- ffmpeg is installed but does not support HEIC decoding (display specific guidance)
- Conversion fails for individual files (log error, continue with others)
- Custom folder path provided but doesn't exist (display error and exit)

10. **User Feedback**: Display status messages showing:

- Which files are being converted
- Which files were skipped as already converted
- When conversion is complete
- Any errors encountered

### Non-Functional Requirements

1. **Usability**: Single double-click to execute; no command-line knowledge required
2. **Accessibility**: Windows shortcut icon in file explorer for quick access
3. **Performance**: Conversion should be reasonably fast (depends on image size and ffmpeg performance)
4. **Reliability**: Should handle unexpected inputs gracefully

## Implementation Plan

### Deliverables

1. **convert-photos.ps1** - PowerShell script that performs the conversion
2. **README.md** - Setup and usage instructions

### Implementation Details

- **Language**: PowerShell script (`.ps1`)
- **Tool**: ffmpeg (with installation guidance if missing or lacking HEIC support)
- **Input**: All `.heic` and `.HEIC` files in designated folder and subfolders
- **Folder Detection**:
  - Default: `C:\Users\%USERNAME%\convert`
  - Custom: Accept folder path as a script parameter
- **Output**: JPG files with descriptive, duplicate-safe naming (e.g., `photo_converted.jpg`, `photo_converted_1.jpg`)
- **Naming**: Convert `photo.heic` → `photo_converted.jpg` (preserve filename, add descriptive suffix, change extension)
- **Processing Scope**: Recurse through subfolders and keep each JPG next to its source HEIC
- **Original Files**: Delete HEIC files after successful conversion
- **Already Converted Rule**: If the expected output JPG already exists, skip the HEIC file instead of creating another JPG
- **Image Quality**: Use an explicit ffmpeg JPG quality setting such as `-q:v 2`
- **Validation**:
  - Verify ffmpeg is on PATH (show installation instructions if missing)
  - Verify ffmpeg can decode HEIC files; if not, show a specific HEIC-support message
  - Verify/create convert folder (create if missing and using default folder)
  - Create desktop shortcut to convert folder if using default folder and folder was created
  - Verify at least one HEIC file exists before processing
- **Desktop Shortcut Creation**:
  - Only when using default folder mode and folder is newly created
  - Place shortcut on user's desktop for easy access
  - Shortcut name: `Convert Photos`
  - Target: `C:\Users\%USERNAME%\convert`
- **Error Handling**: Log errors per file; continue processing remaining files

### User Workflow

**Option 1: Default Folder (First Run)**

1. Run the script: `convert-photos.ps1`
2. Script creates `C:\Users\<username>\convert` folder if it doesn't exist
3. Script creates a desktop shortcut named `Convert Photos` to the convert folder
4. Script displays instructions to place HEIC photos in the convert folder
5. User places HEIC photos in the folder
6. Script exits without attempting conversion
7. Run the script again: `convert-photos.ps1`
8. Watch conversion progress in the command window
9. Press any key when complete
10. Find converted JPG files in the same folders as their source files

**Option 1: Default Folder (Subsequent Runs)**

1. Place HEIC photos into `C:\Users\<username>\convert` folder or its subfolders (or use desktop shortcut)
2. Run the script: `convert-photos.ps1`
3. Watch conversion progress in the command window
4. Press any key when complete
5. Find converted JPG files in the same folders as their source files

**Option 2: Custom Folder**

1. Run the script with a folder parameter: `convert-photos.ps1 -FolderPath "C:\path\to\photos"`
2. Watch conversion progress in the command window
3. Press any key when complete
4. Find converted JPG files in the specified folder and its subfolders

## Success Criteria

✓ Script auto-detects `C:\Users\<username>\convert` folder and processes all HEIC files recursively
✓ Script creates convert folder automatically if it doesn't exist (default mode only)
✓ Script creates a desktop shortcut named `Convert Photos` to the convert folder (default mode, on first run)
✓ Script displays user-friendly instructions for placing photos (only when folder is newly created)
✓ Script accepts custom folder path as parameter
✓ Converted JPG files appear in the same folders as their source HEIC files
✓ Script exits after first-run setup instead of immediately reporting no files found
✓ Original HEIC files are deleted after successful conversion
✓ Files already converted are skipped instead of being converted again
✓ Duplicate JPG filenames are handled correctly with descriptive numbering when needed
✓ ffmpeg installation instructions displayed if ffmpeg not found
✓ Specific guidance displayed if ffmpeg is installed but lacks HEIC support
✓ Errors for individual files are logged; processing continues
✓ Clear status messages guide the user through conversion
✓ Process completes and pauses for user acknowledgment
✓ No errors or crashes during normal operation
