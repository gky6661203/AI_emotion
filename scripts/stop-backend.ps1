$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComposeDir = Join-Path $ProjectRoot 'infra/docker'

Push-Location $ComposeDir
try {
    Write-Host 'Stopping AI Emotion backend stack...' -ForegroundColor Cyan
    & docker compose down
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code $LASTEXITCODE"
    }
    Write-Host 'Backend stack stopped.' -ForegroundColor Green
} finally {
    Pop-Location
}
