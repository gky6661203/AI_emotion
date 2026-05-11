Write-Host "=== Starting AI Emotion Backend ===" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker status..." -ForegroundColor Yellow
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
        Write-Host "Look for the Docker whale icon in your system tray and wait until it turns green." -ForegroundColor Gray
        exit 1
    }
    Write-Host "[OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host ""

# Navigate to docker directory
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ComposeDir = Join-Path $ProjectRoot 'infra/docker'

Write-Host "Stopping existing containers..." -ForegroundColor Yellow
Push-Location $ComposeDir
try {
    & docker compose down -v
    Write-Host "[OK] Existing containers stopped" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Failed to stop existing containers (may be first run)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Building and starting services..." -ForegroundColor Yellow
& docker compose up -d --build

if ($LASTEXITCODE -eq 0) {
    Write-Host "[OK] Services started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Service URLs:" -ForegroundColor Cyan
    Write-Host "  API:      http://localhost:8080" -ForegroundColor Gray
    Write-Host "  Health:   http://localhost:8080/health" -ForegroundColor Gray
    Write-Host "  AI Engine: http://localhost:8090" -ForegroundColor Gray
    Write-Host "  Postgres: localhost:5432" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Checking service status..." -ForegroundColor Yellow
    & docker compose ps
    Write-Host ""
    Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Health check
    try {
        $response = Invoke-WebRequest -Uri 'http://localhost:8080/health' -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "[OK] Backend API is healthy!" -ForegroundColor Green
        }
    } catch {
        Write-Host "[WARN] Backend may still be starting up. Try again in a moment." -ForegroundColor Yellow
    }
} else {
    Write-Host "[ERROR] Failed to start services" -ForegroundColor Red
    Write-Host "Check logs with: docker compose logs" -ForegroundColor Gray
}

Pop-Location
