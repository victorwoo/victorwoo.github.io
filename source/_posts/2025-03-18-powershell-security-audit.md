---
layout: post
date: 2025-03-18 08:00:00
title: "PowerShell 技能连载 - 自动化安全审计"
description: PowerTip of the Day - Automated Security Auditing
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在企业安全运维中，自动化审计能有效发现潜在风险。以下脚本实现系统安全配置审查：

```powershell
function Get-SecurityAudit {
    [CmdletBinding()]
    param(
        [ValidateSet('Basic','Advanced')]
        [string]$AuditLevel = 'Basic'
    )

    $report = [PSCustomObject]@{
        FailedLogins = @()
        OpenPorts = @()
        WeakPermissions = @()
        ComplianceScore = 0
    }

    try {
        # 分析安全事件日志
        $events = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = 4625
            StartTime = (Get-Date).AddDays(-7)
        } -MaxEvents 1000
        $report.FailedLogins = $events | Select-Object -ExpandProperty Message

        # 扫描开放端口
        $report.OpenPorts = Get-NetTCPConnection | 
            Where-Object State -eq 'Listen' | 
            Select-Object LocalAddress,LocalPort

        # 高级权限检查
        if($AuditLevel -eq 'Advanced') {
            $report.WeakPermissions = Get-ChildItem -Path $env:ProgramFiles -Recurse |
                Where-Object { $_.PSAccessControl.Access.IdentityReference -contains 'Everyone' }
        }

        # 计算合规分数
        $totalChecks = 3
        $passed = ([bool]!$report.FailedLogins.Count) + 
                 ([bool]!$report.OpenPorts.Count) + 
                 ([bool]!$report.WeakPermissions.Count)
        $report.ComplianceScore = [math]::Round(($passed / $totalChecks) * 100)
    }
    catch {
        Write-Warning "安全审计异常: $_"
    }

    return $report
}
```

实现原理：
1. 通过Get-WinEvent查询安全事件日志，检测暴力破解行为
2. 使用Get-NetTCPConnection发现异常监听端口
3. 高级模式扫描程序目录权限配置
4. 基于检测结果计算系统合规分数

使用示例：
```powershell
# 基本审计
Get-SecurityAudit

# 高级审计
Get-SecurityAudit -AuditLevel Advanced
```

最佳实践：
1. 与SIEM系统集成实现集中告警
2. 设置基线配置进行差异对比
3. 定期生成PDF格式审计报告
4. 实现自动修复高风险项功能

注意事项：
• 需要本地管理员权限执行
• 端口扫描可能触发安全告警
• 建议在维护窗口执行深度扫描