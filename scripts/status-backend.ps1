$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComposeDir = Join-Path $ProjectRoot 'infra/docker'

Push-Location $ComposeDir
try {
    Write-Host 'Checking AI Emotion backend stack status...' -ForegroundColor Cyan
    & docker compose ps
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code $LASTEXITCODE"
    }
    Write-Host ''
    Write-Host 'Useful URLs:' -ForegroundColor Green
    Write-Host '  API:      http://localhost:8080' -ForegroundColor Gray
    Write-Host '  Health:   http://localhost:8080/health' -ForegroundColor Gray
    Write-Host '  Postgres: localhost:5432' -ForegroundColor Gray
} finally {
    Pop-Location
}
