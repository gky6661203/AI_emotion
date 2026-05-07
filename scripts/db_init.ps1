# AI Emotion System - Database Initialization Script
# Run after PostgreSQL container is ready

$ErrorActionPreference = "Stop"

$CONTAINER_NAME = "race_postgres"
$DB_USER = "race_user"
$DB_NAME = "race_emotion"

Write-Host "Initializing database..." -ForegroundColor Cyan

$sqlFile = Join-Path $PSScriptRoot "../infra/sql/001_init_core_tables.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "SQL file not found: $sqlFile" -ForegroundColor Red
    exit 1
}

Write-Host "Executing: $sqlFile" -ForegroundColor Gray

docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME < $sqlFile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Database initialized successfully!" -ForegroundColor Green
} else {
    Write-Host "Database initialization failed!" -ForegroundColor Red
    exit 1
}

# Also run config seed if exists
$configFile = Join-Path $PSScriptRoot "../infra/sql/003_seed_config.sql"
if (Test-Path $configFile) {
    Write-Host "Running config seed..." -ForegroundColor Gray
    docker exec -i $CONTAINER_NAME psql -U $DB_USER -d $DB_NAME < $configFile
}

Write-Host "Database setup complete!" -ForegroundColor Green