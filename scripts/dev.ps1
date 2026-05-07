param(
    [Parameter()]
    [ValidateSet("infra", "migrate", "ai-engine", "core-api", "smoke", "check")]
    [string]$Service = "check"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot

function Get-ProjectRoot {
    if ($ProjectRoot -eq "") {
        return Split-Path -Parent $PSScriptRoot
    }
    return $ProjectRoot
}

$ROOT = Get-ProjectRoot

switch ($Service) {
    "infra" {
        Write-Host "Starting infrastructure services..." -ForegroundColor Cyan
        Push-Location "$ROOT/infra/docker"
        try {
            docker compose up -d postgres redis minio
            Write-Host "Infrastructure started successfully!" -ForegroundColor Green
        } finally {
            Pop-Location
        }
    }

    "migrate" {
        Write-Host "Running database migrations..." -ForegroundColor Cyan
        docker exec -it race_postgres psql -U race_user -d race_emotion -f /docker-entrypoint-initdb.d/001_init_core_tables.sql
        Write-Host "Database migration completed!" -ForegroundColor Green
    }

    "ai-engine" {
        Write-Host "Starting AI Engine..." -ForegroundColor Cyan
        Push-Location "$ROOT/services/ai-engine"
        try {
            if (Test-Path "venv") {
                & "$ROOT/services/ai-engine/venv/Scripts/python" -m uvicorn main:app --host 0.0.0.0 --port 8090 --reload
            } else {
                py -m uvicorn main:app --host 0.0.0.0 --port 8090 --reload
            }
        } finally {
            Pop-Location
        }
    }

    "core-api" {
        Write-Host "Starting Core API..." -ForegroundColor Cyan
        Push-Location "$ROOT/services/core-api"
        try {
            cargo run
        } finally {
            Pop-Location
        }
    }

    "smoke" {
        Write-Host "Running smoke tests..." -ForegroundColor Cyan
        Push-Location $ROOT
        try {
            py ./scripts/smoke_test.py
        } finally {
            Pop-Location
        }
    }

    "check" {
        Write-Host "Running full check (init + smoke test)..." -ForegroundColor Cyan
        & $PSCommandPath -Service infra
        Start-Sleep -Seconds 5
        & $PSCommandPath -Service migrate
        Start-Sleep -Seconds 2
        & $PSCommandPath -Service smoke
    }
}