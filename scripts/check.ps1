# Runs every automated gate. Run this before you commit, and before you merge.
#
#   pwsh scripts/check.ps1
#
# Exits non-zero if anything fails, so it works as a git hook and later as CI.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$app = Join-Path $root 'app'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $env:PATH = "C:\src\flutter\bin;$env:PATH"
}

Push-Location $app
$failed = @()

Write-Host "`n[1/3] format" -ForegroundColor Cyan
dart format --set-exit-if-changed --output=none . 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) {
    $failed += 'format (run: dart format .)'
}

Write-Host "`n[2/3] analyze" -ForegroundColor Cyan
flutter analyze 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { $failed += 'analyze' }

Write-Host "`n[3/3] test" -ForegroundColor Cyan
flutter test 2>&1 | Out-Host
if ($LASTEXITCODE -ne 0) { $failed += 'test' }

Pop-Location

Write-Host ''
if ($failed.Count -eq 0) {
    Write-Host 'PASS - all automated gates green.' -ForegroundColor Green
    Write-Host 'Now walk docs/REVIEW-CHECKLIST.md for what tests cannot catch.'
    exit 0
}

Write-Host "FAIL - $($failed -join ', ')" -ForegroundColor Red
exit 1
