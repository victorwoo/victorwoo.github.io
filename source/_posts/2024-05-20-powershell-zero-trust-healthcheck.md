---
layout: post
date: 2024-05-20 08:00:00
title: "PowerShell 技能连载 - 零信任架构设备健康检查"
description: "基于零信任原则的PowerShell设备健康验证系统"
categories:
- powershell
- security
tags:
- zerotrust
- compliance
- healthcheck
---

```powershell
function Invoke-DeviceHealthCheck {
    [CmdletBinding()]
    param(
        [ValidateSet('Basic','Full')]
        [string]$ScanLevel = 'Basic'
    )

    $healthReport = [PSCustomObject]@{
        Timestamp     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        DeviceID      = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
        Compliance    = $true
        SecurityScore = 100
        Findings      = @()
    }

    # 基础检查项
    $checks = @(
        { Get-CimInstance -ClassName Win32_BIOS | Select-Object Version,ReleaseDate },
        { Get-WindowsUpdateLog -Last 7 | Where Status -ne 'Installed' },
        { Get-NetFirewallProfile | Where Enabled -eq $false }
    )

    if ($ScanLevel -eq 'Full') {
        $checks += @(
            { Get-Service -Name WinDefend | Where Status -ne 'Running' },
            { Get-ChildItem 'C:\Temp' -Recurse -File | Where {$_.LastWriteTime -gt (Get-Date).AddDays(-1)} },
            { Get-LocalUser | Where PasswordNeverExpires -eq $true }
        )
    }

    foreach ($check in $checks) {
        try {
            $result = & $check
            if ($result) {
                $healthReport.Findings += [PSCustomObject]@{
                    CheckName = $check.ToString().Split('{')[1].Trim()
                    Status    = 'NonCompliant'
                    Details   = $result | ConvertTo-Json -Compress
                }
                $healthReport.SecurityScore -= 10
                $healthReport.Compliance = $false
            }
        }
        catch {
            Write-Warning "检查项执行失败: $_"
        }
    }

    $healthReport | Export-Clixml -Path "$env:TEMP\DeviceHealthReport_$(Get-Date -Format yyyyMMdd).xml"
    return $healthReport
}
```

**核心功能**：
1. 多层级设备健康扫描（基础/完整模式）
2. 实时安全态势评分机制
3. 自动化合规性验证
4. XML格式审计报告生成

**典型应用场景**：
- 企业设备入网前合规检查
- 零信任架构下的持续设备验证
- 远程办公终端安全审计
- 安全基线的快速验证