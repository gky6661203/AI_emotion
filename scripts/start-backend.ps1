param(
    [Parameter()]
    [switch]$Rebuild,

    [Parameter()]
    [switch]$ResetData
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComposeDir = Join-Path $ProjectRoot 'infra/docker'

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    Push-Location $ComposeDir
    try {
        & docker compose @Args
        if ($LASTEXITCODE -ne 0) {
            throw "docker compose failed with exit code $LASTEXITCODE"
        }
    } finally {
        Pop-Location
    }
}

Write-Host 'Starting AI Emotion backend stack...' -ForegroundColor Cyan
Write-Host 'Tip: first-time use can take a few minutes while Docker downloads images.' -ForegroundColor Gray

if ($ResetData) {
    Write-Host 'Resetting containers and volumes...' -ForegroundColor Yellow
    Invoke-Compose -Args @('down', '-v', '--remove-orphans')
}

if ($Rebuild) {
    Write-Host 'Rebuilding images...' -ForegroundColor Yellow
}
Invoke-Compose -Args @('up', '-d', '--build')

Write-Host 'Waiting for backend health check...' -ForegroundColor Yellow
$healthOk = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $response = Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 3
        if ($response.StatusCode -eq 200) {
            $healthOk = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 2
    }
}

Write-Host ''
if ($healthOk) {
    Write-Host 'Backend started successfully.' -ForegroundColor Green
} else {
    Write-Host 'Backend containers started, but health check did not respond yet.' -ForegroundColor Yellow
}
Write-Host 'Useful URLs:' -ForegroundColor Green
Write-Host '  API:       http://172.26.48.1:8080' -ForegroundColor Gray
Write-Host '  Health:    http://172.26.48.1:8080/health' -ForegroundColor Gray
Write-Host '  Postgres:  localhost:5432' -ForegroundColor Gray
Write-Host '  Stop:      .\scripts\stop-backend.ps1' -ForegroundColor Gray
Write-Host '  Status:    .\scripts\status-backend.ps1' -ForegroundColor Gray
Write-Host ''
Write-Host 'If you need to reinitialize the database, run:' -ForegroundColor Yellow
Write-Host '  .\scripts\start-backend.ps1 -ResetData -Rebuild' -ForegroundColor Gray
