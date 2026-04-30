# Copilot Instructions

## Scope

This repository is a small PowerShell utility, not a multi-package project. Keep changes focused, minimal, and consistent with the current single-script structure.

## Repo Map

- [README.md](../README.md) is the source of truth for setup, usage, requirements, and troubleshooting.
- [plan.md](../plan.md) captures the original requirements and design intent.
- [convert-photos.ps1](../convert-photos.ps1) contains the production logic.
- [tests/convert-photos.Tests.ps1](../tests/convert-photos.Tests.ps1) contains the Pester integration tests.

Link to those files instead of duplicating their full content in PRs or follow-up documentation.

## Working Conventions

- Treat this as a Windows-first PowerShell script. Prefer `pwsh` for local commands, but preserve compatibility with Windows PowerShell 5.1 unless the task explicitly changes support.
- Keep `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'` semantics intact.
- Preserve the script's exit-code contract: `0` for success or no-op success paths, `1` for error paths.
- Preserve the default-folder workflow unless the task explicitly changes it: no `-FolderPath` means `%USERPROFILE%\convert`, first run creates the folder and shortcuts, then exits without converting.
- Preserve the conversion contract unless requirements change: output names use `_converted`, existing expected outputs are skipped, numbered suffixes resolve collisions, and source `.heic` files are deleted only after successful conversion.
- `ffmpeg` on `PATH` is a hard prerequisite for real runs. Do not replace the decode probe with a weaker capability check.
- Use `$env:HEIC_TO_JPG_NO_PAUSE = '1'` for automation or tests so the script does not block on `Read-Host`.

## Testing

- Run the focused test suite with `pwsh -NoProfile -Command "Invoke-Pester ./tests/convert-photos.Tests.ps1"`.
- If you change user-visible behavior, exit codes, shortcut setup, ffmpeg detection, naming rules, or deletion behavior, update the Pester tests in [tests/convert-photos.Tests.ps1](../tests/convert-photos.Tests.ps1).
- The tests isolate filesystem effects with `$TestDrive` and stub `ffmpeg` via temporary `PATH` entries. Keep new tests aligned with that pattern.
- Some tests use absolute paths to this repo's script file. Be careful when refactoring invocation patterns.

## Documentation Expectations

- Update [README.md](../README.md) whenever setup, prerequisites, usage, or troubleshooting behavior changes.
- Update [plan.md](../plan.md) only if the underlying requirements or intended behavior actually change.

## Commit And PR Conventions

- Use Conventional Commit prefixes such as `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, and `chore:`.
- Prefer emoji-prefixed PR titles that match the change, for example `🐛 Fix missing HEIC probe handling` or `🧪 Add shortcut behavior tests`.
- Structure PR bodies with these sections:
  - `### What does this PR do?`
  - `### Why are we doing this?`
  - `### How should this be tested?`
  - `### Any deployment notes?`

## Change Style

- Prefer small, local edits over broad rewrites.
- Do not add new dependencies unless they are clearly necessary.
- Match the existing messaging style: concise `Write-Host` output through the helper functions.
- Add concise PowerShell help blocks above each function so `Get-Help` and editor tooltips have something useful.
- When changing behavior, favor updating tests and docs in the same change.
