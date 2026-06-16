# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Fixed
- Quoted `$sourcePath` and `$outputPath` in the ffmpeg conversion invocation, and `$SampleHeicPath` in the HEIC support probe, so paths containing spaces no longer break ffmpeg argument parsing ([#6](https://github.com/J-MaFf/heic-to-jpg/pull/12))
