# 添加防火墙规则允许8080端口
Write-Host "Adding firewall rule for port 8080..." -ForegroundColor Cyan

# 检查是否已有规则
$existingRule = Get-NetFirewallRule -DisplayName "AI Emotion Backend" -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "Rule already exists, updating..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName "AI Emotion Backend"
}

# 创建新规则
New-NetFirewallRule -DisplayName "AI Emotion Backend" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 8080 `
    -Action Allow `
    -Profile Any `
    -Description "Allow incoming connections to AI Emotion backend on port 8080"

Write-Host "Firewall rule added successfully!" -ForegroundColor Green
Write-Host "You can now access the backend from VMs and other devices." -ForegroundColor Gray
