---
layout: post
date: 2024-08-23 08:00:00
title: "PowerShell 技能连载 - 红队渗透测试自动化框架"
description: "实现权限提升检测与横向移动路径自动化分析"
categories:
- powershell
- security
tags:
- red-team
- privilege-escalation
- lateral-movement
---

```powershell
function Invoke-RedTeamScan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetRange,
        
        [ValidateSet('Basic','Advanced')]
        [string]$ScanMode = 'Basic'
    )

    $threatReport = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        VulnerableSystems = @()
        AttackPaths = @()
        RiskScore = 0
    }

    try {
        # 检测本地权限提升漏洞
        $localVulns = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |
            Where-Object { $_.GetValue('DisplayName') -match '脆弱服务' }
        if ($localVulns) {
            $threatReport.VulnerableSystems += [PSCustomObject]@{
                SystemName = $env:COMPUTERNAME
                Vulnerability = '本地权限提升'
                CVE = 'CVE-2024-XXXX'
            }
        }

        # 高级模式横向移动检测
        if ($ScanMode -eq 'Advanced') {
            $networkSystems = Test-NetConnection -ComputerName $TargetRange -Port 445 |
                Where-Object TcpTestSucceeded
            
            $networkSystems | ForEach-Object {
                $shares = Get-SmbShare -ComputerName $_.RemoteAddress -ErrorAction SilentlyContinue
                if ($shares) {
                    $threatReport.AttackPaths += [PSCustomObject]@{
                        Source = $env:COMPUTERNAME
                        Target = $_.RemoteAddress
                        AttackVector = 'SMB共享漏洞'
                    }
                }
            }
        }

        # 计算风险评分
        $threatReport.RiskScore = [math]::Min(100, ($threatReport.VulnerableSystems.Count * 30) + ($threatReport.AttackPaths.Count * 20))
    }
    catch {
        Write-Error "渗透测试失败: $_"
    }

    # 生成红队行动报告
    $threatReport | ConvertTo-Json | Out-File -Path "$env:TEMP/RedTeamReport_$(Get-Date -Format yyyyMMdd).json"
    return $threatReport
}
```

**核心功能**：
1. 本地权限提升漏洞检测
2. 网络横向移动路径分析
3. SMB共享漏洞自动化扫描
4. 动态风险评分系统

**应用场景**：
- 红队渗透测试演练
- 企业网络安全评估
- 攻击路径可视化
- 安全防御策略验证