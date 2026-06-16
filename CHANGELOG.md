# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- `-DryRun` switch: when passed, the script lists which files would be converted and deleted without performing any actual operations, so users can verify what will be touched before committing ([#9](https://github.com/J-MaFf/heic-to-jpg/pull/15))

### Changed
- Moved `plan.md` from the repo root to `docs/plan.md` to reduce root clutter ([#10](https://github.com/J-MaFf/heic-to-jpg/pull/16))

### Fixed
- `Invoke-PhotoConversion` now returns exit code `1` when `$failedCount > 0`, so callers (CI, wrapper scripts) can distinguish a partial-failure run from a clean run ([#11](https://github.com/J-MaFf/heic-to-jpg/pull/17))
- Added a 9999-iteration guard to `Get-UniqueOutputPath` so the function throws a descriptive error instead of spinning indefinitely when the filesystem is full or `Test-Path` misbehaves ([#8](https://github.com/J-MaFf/heic-to-jpg/pull/14))
- Replaced hardcoded developer absolute path in `tests/convert-photos.Tests.ps1` (8 occurrences) with `"$PSScriptRoot\..\convert-photos.ps1"` so the test suite resolves correctly on any machine ([#7](https://github.com/J-MaFf/heic-to-jpg/pull/13))
- Quoted `$sourcePath` and `$outputPath` in the ffmpeg conversion invocation, and `$SampleHeicPath` in the HEIC support probe, so paths containing spaces no longer break ffmpeg argument parsing ([#6](https://github.com/J-MaFf/heic-to-jpg/pull/12))
