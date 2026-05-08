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
        & "$ROOT/scripts/db_init.ps1"
        Write-Host "Database migration completed!" -ForegroundColor Green
    }

    "ai-engine" {
        Write-Host "Starting AI Engine..." -ForegroundColor Cyan
        Push-Location "$ROOT/services/ai-engine"
        try {
            $python = "D:\python\anaconda3\python.exe"
            
            & $python -m pip install fastapi==0.109.0 uvicorn[standard]==0.27.0 pydantic==1.10.14 python-multipart==0.0.6 httpx==0.26.0 jinja2==3.1.3 -q
            
            & $python -m uvicorn main:app --host 0.0.0.0 --port 8090 --reload
        } finally {
            Pop-Location
        }
    }

    "core-api" {
        Write-Host "Starting Core API (Java)..." -ForegroundColor Cyan
        Push-Location "$ROOT/services/core-api-java"
        try {
            Write-Host "Building project..." -ForegroundColor Gray
            mvn clean package -DskipTests -q
            
            Write-Host "Running Core API on http://localhost:8080" -ForegroundColor Green
            java -jar target/core-api-1.0.0.jar
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
