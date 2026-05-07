param(
    [Parameter()]
    [string]$CoreApiUrl = "http://localhost:8080",
    [Parameter()]
    [string]$AiEngineUrl = "http://localhost:8090",
    [Parameter()]
    [int]$TimeoutSeconds = 10
)

$ErrorActionPreference = "Stop"

function Test-Endpoint {
    param([string]$Url, [string]$Name)
    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec $TimeoutSeconds -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "[OK] $Name is healthy" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[FAIL] $Name returned status $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[FAIL] $Name is not reachable: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Write-Host "=== AI Emotion Smoke Test ===" -ForegroundColor Cyan
Write-Host "Core API: $CoreApiUrl" -ForegroundColor Gray
Write-Host "AI Engine: $AiEngineUrl" -ForegroundColor Gray
Write-Host ""

$allPassed = $true

Write-Host "1. Testing Core API health..." -ForegroundColor Yellow
$allPassed = (Test-Endpoint "$CoreApiUrl/health" "Core API") -and $allPassed

Write-Host ""
Write-Host "2. Testing AI Engine health..." -ForegroundColor Yellow
$allPassed = (Test-Endpoint "$AiEngineUrl/health" "AI Engine") -and $allPassed

Write-Host ""
Write-Host "3. Testing anonymous user creation..." -ForegroundColor Yellow
try {
    $body = @{
        campus = "测试校区"
        enrollment_year = 2024
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/auth/anonymous" -Method POST -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSeconds
    if ($response.user -and $response.token) {
        Write-Host "[OK] Anonymous user created: $($response.user.id)" -ForegroundColor Green
        $token = $response.token
    } else {
        Write-Host "[FAIL] Invalid response" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
    $allPassed = $false
}

if ($token) {
    Write-Host ""
    Write-Host "4. Testing device binding..." -ForegroundColor Yellow
    try {
        $headers = @{ "Authorization" = "Bearer $token" }
        $body = @{
            device_id = "test_device_001"
            device_type = "phone"
            device_name = "测试手机"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/devices/bind" -Method POST -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSeconds
        if ($response.device) {
            Write-Host "[OK] Device bound: $($response.device.id)" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Invalid response" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }

    Write-Host ""
    Write-Host "5. Testing chat message..." -ForegroundColor Yellow
    try {
        $body = @{ content = "我今天心情不太好" } | ConvertTo-Json
        $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/chat/messages" -Method POST -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSeconds
        if ($response.message) {
            Write-Host "[OK] Message sent: $($response.message.id)" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Invalid response" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }

    Write-Host ""
    Write-Host "6. Testing private letter creation..." -ForegroundColor Yellow
    try {
        $body = @{
            title = "测试树洞"
            content = "这是我的一条测试树洞消息"
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/private-letters" -Method POST -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSeconds
        if ($response.letter) {
            Write-Host "[OK] Letter created: $($response.letter.id)" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Invalid response" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }

    Write-Host ""
    Write-Host "7. Testing voice record upload..." -ForegroundColor Yellow
    try {
        $body = @{
            file_url = "file://test/voice_001.m4a"
            duration_seconds = 30
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/voice-records" -Method POST -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec $TimeoutSeconds
        if ($response.voice_record) {
            Write-Host "[OK] Voice record created: $($response.voice_record.id)" -ForegroundColor Green
            $voiceRecordId = $response.voice_record.id
        } else {
            Write-Host "[FAIL] Invalid response" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }

    if ($voiceRecordId) {
        Write-Host ""
        Write-Host "8. Testing voice transcription..." -ForegroundColor Yellow
        try {
            $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/voice-records/$voiceRecordId/transcribe" -Method POST -Headers $headers -Body "{}" -ContentType "application/json" -TimeoutSec $TimeoutSeconds
            if ($response.transcript) {
                Write-Host "[OK] Transcription completed" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] Invalid response" -ForegroundColor Red
                $allPassed = $false
            }
        } catch {
            Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
            $allPassed = $false
        }

        Write-Host ""
        Write-Host "9. Testing voice emotion analysis..." -ForegroundColor Yellow
        try {
            $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/voice-records/$voiceRecordId/analyze" -Method POST -Headers $headers -Body "{}" -ContentType "application/json" -TimeoutSec $TimeoutSeconds
            if ($response.emotion) {
                Write-Host "[OK] Emotion analysis: $($response.emotion)" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] Invalid response" -ForegroundColor Red
                $allPassed = $false
            }
        } catch {
            Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
            $allPassed = $false
        }
    }

    Write-Host ""
    Write-Host "10. Testing recommendations..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/recommendations/current?limit=3" -Method GET -Headers $headers -TimeoutSec $TimeoutSeconds
        if ($response.recommendations) {
            Write-Host "[OK] Got $($response.recommendations.Count) recommendations" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Invalid response" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }

    Write-Host ""
    Write-Host "11. Testing emotion report..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "$CoreApiUrl/api/emotions/report?days=7" -Method GET -Headers $headers -TimeoutSec $TimeoutSeconds
        if ($response.user_id) {
            Write-Host "[OK] Emotion report generated" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Invalid response" -ForegroundColor Red
            $allPassed = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allPassed = $false
    }
}

Write-Host ""
Write-Host "=== Smoke Test Complete ===" -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some tests failed!" -ForegroundColor Red
    exit 1
}