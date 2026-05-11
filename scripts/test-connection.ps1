# 测试后端连接
Write-Host "=== 测试后端连接 ===" -ForegroundColor Cyan
Write-Host ""

# 测试本地连接
Write-Host "1. 测试 localhost:8080..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   [成功] localhost:8080 可访问" -ForegroundColor Green
    Write-Host "   响应: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "   [失败] localhost:8080 无法访问" -ForegroundColor Red
    Write-Host "   错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 测试局域网IP连接
$localIP = "10.16.106.237"
Write-Host "2. 测试 $localIP`:8080..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://$localIP`:8080/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "   [成功] $localIP`:8080 可访问" -ForegroundColor Green
    Write-Host "   响应: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "   [失败] $localIP`:8080 无法访问" -ForegroundColor Red
    Write-Host "   错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 测试端口连通性
Write-Host "3. 测试端口连通性..." -ForegroundColor Yellow
$testResult = Test-NetConnection -ComputerName $localIP -Port 8080 -WarningAction SilentlyContinue
if ($testResult.TcpTestSucceeded) {
    Write-Host "   [成功] 端口 8080 可以连接" -ForegroundColor Green
} else {
    Write-Host "   [失败] 端口 8080 无法连接" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Tips:" -ForegroundColor Yellow
Write-Host "- If localhost works but IP fails, check firewall" -ForegroundColor Gray
Write-Host "- VM may need special config to access host" -ForegroundColor Gray
Write-Host "- Make sure backend is running: docker ps" -ForegroundColor Gray
