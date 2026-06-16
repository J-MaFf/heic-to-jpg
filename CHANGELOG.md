# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- Added a 9999-iteration guard to `Get-UniqueOutputPath` so the function throws a descriptive error instead of spinning indefinitely when the filesystem is full or `Test-Path` misbehaves ([#8](https://github.com/J-MaFf/heic-to-jpg/pull/14))
- Replaced hardcoded developer absolute path in `tests/convert-photos.Tests.ps1` (8 occurrences) with `"$PSScriptRoot\..\convert-photos.ps1"` so the test suite resolves correctly on any machine ([#7](https://github.com/J-MaFf/heic-to-jpg/pull/13))
- Quoted `$sourcePath` and `$outputPath` in the ffmpeg conversion invocation, and `$SampleHeicPath` in the HEIC support probe, so paths containing spaces no longer break ffmpeg argument parsing ([#6](https://github.com/J-MaFf/heic-to-jpg/pull/12))
