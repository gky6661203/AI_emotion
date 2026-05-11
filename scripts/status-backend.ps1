$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComposeDir = Join-Path $ProjectRoot 'infra/docker'

Push-Location $ComposeDir
try {
    Write-Host 'AI Emotion backend stack status:' -ForegroundColor Cyan
    & docker compose ps
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}
