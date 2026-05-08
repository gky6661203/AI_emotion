
param(
    [string]$Profile = "default"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting Core API (Java)..." -ForegroundColor Cyan

$projectDir = Join-Path $PSScriptRoot "..\services\core-api-java"
$jarPath = Join-Path $projectDir "target\core-api-1.0.0.jar"

if (-not (Test-Path $jarPath)) {
    Write-Host "Building project..." -ForegroundColor Gray
    Set-Location $projectDir
    mvn clean package -DskipTests -q
    
    if (-not (Test-Path $jarPath)) {
        Write-Host "Build failed! Jar not found: $jarPath" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Running Core API on http://localhost:8080" -ForegroundColor Green
java -jar $jarPath
