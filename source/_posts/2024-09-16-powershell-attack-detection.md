---
layout: post
date: 2024-09-16 08:00:00
title: "PowerShell 技能连载 - 基于ATT&CK框架的进程行为分析"
description: "实现可疑进程的自动化威胁检测"
categories:
- powershell
- security
tags:
- att&ck
- threat-hunting
- process-analysis
---

```powershell
function Invoke-ProcessBehaviorAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $techniques = Invoke-RestMethod -Uri 'https://attack.mitre.org/api/techniques/'
    $processes = Get-CimInstance -ClassName Win32_Process -ComputerName $ComputerName

    $report = [PSCustomObject]@{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        SuspiciousProcesses = @()
        MITRETechniques = @()
    }

    $processes | ForEach-Object {
        $behaviorScore = 0
        $matchedTechs = @()

        # 检测隐藏进程
        if ($_.ParentProcessId -ne 1 -and -not (Get-Process -Id $_.ParentProcessId -ErrorAction SilentlyContinue)) {
            $behaviorScore += 20
            $matchedTechs += 'T1055'  # Process Injection
        }

        # 检测异常内存操作
        if ($_.WorkingSetSize -gt 1GB) {
            $behaviorScore += 15
            $matchedTechs += 'T1056'  # Memory Allocation
        }

        if ($behaviorScore -gt 25) {
            $report.SuspiciousProcesses += [PSCustomObject]@{
                ProcessName = $_.Name
                ProcessId = $_.ProcessId
                Score = $behaviorScore
                CommandLine = $_.CommandLine
            }
            $report.MITRETechniques += $matchedTechs | Select-Object @{n='TechniqueID';e={$_}}, @{n='Description';e={$techniques.techniques.Where{$_.id -eq $_}.name}}
        }
    }

    $report | ConvertTo-Json -Depth 3 | Out-File "$env:TEMP/ProcessAnalysis_$(Get-Date -Format yyyyMMdd).json"
    return $report
}
```

**核心功能**：
1. ATT&CK技术特征匹配
2. 进程行为异常评分
3. 自动化威胁检测
4. JSON报告生成

**典型应用场景**：
- 企业终端安全监控
- 红队攻击痕迹分析
- 蓝队防御策略验证
- 安全事件快速响应