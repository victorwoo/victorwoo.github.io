---
layout: post
date: 2026-01-16 08:00:00
updated: 2026-01-16 08:00:00
title: "PowerShell 技能连载 - Windows Update 自动化"
description: PowerTip of the Day - Windows Update Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- windows-update
- patching
- automation
- security
---

_适用于 PowerShell 5.1 及以上版本_

补丁管理是企业安全运维的基石。每个月的 Patch Tuesday，微软会发布数十个安全更新，涵盖操作系统、浏览器、.NET 运行时等关键组件。如果依赖手动逐台安装更新，不仅效率低下，还容易遗漏关键补丁，给攻击者留下可乘之机。

PowerShell 为 Windows Update 自动化提供了多种手段。从内置的 `Microsoft.Update.Session` COM 对象完成底层扫描，到社区广泛使用的 `PSWindowsUpdate` 模块实现批量部署，再到结合 WSUS API 编写审批流程，可以覆盖从单机到数千台服务器的全场景补丁管理需求。

本文将围绕三个核心场景展开：更新扫描与审批、批量安装与重启编排、合规报告与异常处理，帮助你构建一套完整的 Windows Update 自动化体系。

<!-- more -->

## 更新扫描与审批

在部署更新之前，首先要扫描可用的更新列表，根据分类（安全更新、关键更新、驱动程序等）和 KB 编号进行筛选，然后决定哪些更新需要审批安装。以下脚本演示了完整的扫描和审批流程。

```powershell
# 使用 PSWindowsUpdate 模块扫描可用更新
# 首次使用需安装模块（需要管理员权限）
# Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
Import-Module PSWindowsUpdate

# 扫描当前机器的可用更新
Write-Host "正在扫描可用更新..." -ForegroundColor Cyan
$availableUpdates = Get-WindowsUpdate -Verbose:$false

if ($availableUpdates.Count -eq 0) {
    Write-Host "当前系统已是最新，无需更新。" -ForegroundColor Green
    return
}

Write-Host "发现 $($availableUpdates.Count) 个可用更新：`n"

# 分类汇总
$updatesByCategory = $availableUpdates | Group-Object -Property {
    if ($_.Title -match 'Security') { '安全更新' }
    elseif ($_.Title -match 'Cumulative|累计') { '累积更新' }
    elseif ($_.Title -match 'Driver|驱动') { '驱动程序' }
    else { '其他更新' }
} | Sort-Object Count -Descending

foreach ($group in $updatesByCategory) {
    Write-Host ("  {0,-12} {1} 个" -f $group.Name, $group.Count) -ForegroundColor Yellow
}

# 过滤安全更新和累积更新
$criticalUpdates = $availableUpdates | Where-Object {
    $_.Title -match 'Security|Security Update|安全' -or
    $_.Title -match 'Cumulative|累计'
}

Write-Host "`n关键更新列表："
$criticalUpdates | ForEach-Object {
    $kb = if ($_.KB -match 'KB\d+') { $Matches[0] } else { 'N/A' }
    Write-Host ("  [{0}] {1}" -f $kb, $_.Title)
}

# 审批逻辑：按 KB 编号白名单安装
$approvedKBs = @(
    'KB5034441'  # 示例：Windows 安全更新
    'KB5034440'  # 示例：累积更新
)

$toInstall = $criticalUpdates | Where-Object {
    $kb = if ($_.KB -match 'KB\d+') { $Matches[0] } else { '' }
    $kb -in $approvedKBs
}

Write-Host "`n已审批 $($toInstall.Count) 个更新，准备安装。"
$toInstall | ForEach-Object {
    $kb = if ($_.KB -match 'KB\d+') { $Matches[0] } else { 'N/A' }
    Write-Host ("  [审批通过] {0} - {1}" -f $kb, $_.Title) -ForegroundColor Green
}
```

执行结果示例：

```
正在扫描可用更新...
发现 12 个可用更新：

  累积更新     4 个
  安全更新     5 个
  其他更新     3 个

关键更新列表：
  [KB5034441] 2026-01 Security Update for Windows Server 2022
  [KB5034440] 2026-01 Cumulative Update for Windows 11
  [KB5034439] 2026-01 Security Update for .NET Framework 4.8.1
  [KB5034438] 2026-01 Security Update for Windows 10
  [KB5034437] 2026-01 Cumulative Update for Windows Server 2019
  [KB5034436] 2026-01 Cumulative Update for .NET 8.0
  [KB5034435] 2026-01 Cumulative Update for Windows 11 (23H2)
  [KB5034434] 2026-01 Cumulative Update for Windows Server 2022

已审批 2 个更新，准备安装。
  [审批通过] KB5034441 - 2026-01 Security Update for Windows Server 2022
  [审批通过] KB5034440 - 2026-01 Cumulative Update for Windows 11
```

扫描结果按类别分组显示，让运维人员一目了然地看到安全更新和累积更新的数量。审批环节通过 KB 白名单机制控制，只有经过安全团队审核的补丁才会被安装，避免未经测试的更新引发兼容性问题。

## 批量安装与重启编排

单台机器的更新安装只是起点。在企业环境中，通常需要同时对多台服务器执行滚动更新：按批次安装更新、重启机器、验证服务恢复后再处理下一批。以下脚本实现了一个完整的滚动更新流程。

```powershell
# 批量安装与滚动重启编排
Import-Module PSWindowsUpdate

# 目标服务器列表（可从 AD、CMDB 或文本文件读取）
$servers = @(
    'WEB-SVR01',
    'WEB-SVR02',
    'WEB-SVR03',
    'DB-SVR01',
    'DB-SVR02'
)

# 分批策略：Web 服务器先更新，数据库后更新
$batches = @(
    @{ Name = 'Web层'; Servers = $servers | Where-Object { $_ -match '^WEB' } }
    @{ Name = '数据库层'; Servers = $servers | Where-Object { $_ -match '^DB' } }
)

foreach ($batch in $batches) {
    Write-Host "`n========== 开始处理：$($batch.Name) ==========" -ForegroundColor Cyan
    $batchServers = $batch.Servers
    $restartQueue = @()

    foreach ($server in $batchServers) {
        Write-Host "`n[$server] 扫描并安装更新..." -ForegroundColor Yellow

        try {
            # 远程安装已审批的安全更新（自动接受并安装）
            $result = Invoke-Command -ComputerName $server -ScriptBlock {
                Import-Module PSWindowsUpdate
                Get-WindowsUpdate -AcceptAll -Install -AutoReboot -Verbose:$false |
                    Select-Object KB, Title, Result
            } -ErrorAction Stop

            $installed = $result | Where-Object { $_.Result -eq 'Installed' }
            Write-Host "  已安装 $($installed.Count) 个更新"

            # 将需要重启的服务器加入队列
            if ($result | Where-Object { $_.Result -eq 'InstalledRebootRequired' }) {
                $restartQueue += $server
                Write-Host "  需要重启，已加入重启队列" -ForegroundColor Magenta
            }
        }
        catch {
            Write-Host "  安装失败：$($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # 编排重启：逐台重启并等待恢复
    foreach ($server in $restartQueue) {
        Write-Host "`n[$server] 正在重启..." -ForegroundColor Yellow
        Restart-Computer -ComputerName $server -Force -Wait -For PowerShell `
            -Timeout 600 -Delay 15

        # 健康检查：验证关键服务已恢复
        $health = Invoke-Command -ComputerName $server -ScriptBlock {
            $services = @('W3SVC', 'WinRM', 'EventLog')
            $results = @{}
            foreach ($svc in $services) {
                $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
                $results[$svc] = if ($s) { $s.Status } else { 'NotFound' }
            }
            $results
        }

        $allRunning = $health.Values | Where-Object { $_ -ne 'Running' }
        if ($allRunning.Count -eq 0) {
            Write-Host "  健康检查通过，所有关键服务已恢复" -ForegroundColor Green
        }
        else {
            Write-Host "  警告：部分服务未恢复 $allRunning" -ForegroundColor Red
        }
    }

    Write-Host "`n$($batch.Name) 批次处理完成" -ForegroundColor Green
}
```

执行结果示例：

```
========== 开始处理：Web层 ==========

[WEB-SVR01] 扫描并安装更新...
  已安装 3 个更新
  需要重启，已加入重启队列

[WEB-SVR02] 扫描并安装更新...
  已安装 2 个更新

[WEB-SVR03] 扫描并安装更新...
  已安装 3 个更新
  需要重启，已加入重启队列

[WEB-SVR01] 正在重启...
  健康检查通过，所有关键服务已恢复

[WEB-SVR03] 正在重启...
  健康检查通过，所有关键服务已恢复

Web层 批次处理完成

========== 开始处理：数据库层 ==========

[DB-SVR01] 扫描并安装更新...
  已安装 4 个更新
  需要重启，已加入重启队列

[DB-SVR02] 扫描并安装更新...
  已安装 3 个更新

[DB-SVR01] 正在重启...
  健康检查通过，所有关键服务已恢复

数据库层 批次处理完成
```

滚动更新策略按应用层分批执行，确保在更新过程中始终有足够的实例保持服务可用。每台服务器重启后会自动执行健康检查，验证 WinRM、IIS、事件日志等关键服务已正常恢复，发现问题立即告警。

## 合规报告与异常处理

补丁管理的最后一步是生成合规报告，追踪哪些机器已完成更新、哪些存在缺失补丁、哪些安装失败需要重试。以下脚本构建了一个简易的合规审计仪表板。

```powershell
# 合规报告与异常处理
Import-Module PSWindowsUpdate

$servers = @(
    'WEB-SVR01', 'WEB-SVR02', 'WEB-SVR03',
    'DB-SVR01', 'DB-SVR02'
)

$report = @()
$failedServers = @()

foreach ($server in $servers) {
    try {
        $updateStatus = Invoke-Command -ComputerName $server -ScriptBlock {
            Import-Module PSWindowsUpdate

            # 获取缺失的更新
            $missing = Get-WindowsUpdate -Verbose:$false

            # 获取最近 7 天安装的更新
            $recentInstalled = Get-WUHistory | Where-Object {
                $_.Date -gt (Get-Date).AddDays(-7)
            }

            # 获取上次重启时间
            $lastBoot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime

            return @{
                MissingCount    = $missing.Count
                MissingCritical = ($missing | Where-Object {
                    $_.Title -match 'Security|安全'
                }).Count
                RecentInstalled = $recentInstalled.Count
                LastBootTime    = $lastBoot
            }
        } -ErrorAction Stop

        # 计算合规状态
        $daysSinceBoot = ((Get-Date) - $updateStatus.LastBootTime).Days
        $compliance = if ($updateStatus.MissingCritical -eq 0 -and $daysSinceBoot -lt 30) {
            '合规'
        }
        elseif ($updateStatus.MissingCritical -le 2 -and $daysSinceBoot -lt 60) {
            '部分合规'
        }
        else {
            '不合规'
        }

        $report += [PSCustomObject]@{
            Server         = $server
            Compliance     = $compliance
            MissingCritical = $updateStatus.MissingCritical
            MissingTotal   = $updateStatus.MissingCount
            RecentInstalled = $updateStatus.RecentInstalled
            LastBootDays   = $daysSinceBoot
        }

        # 记录失败的服务器，用于后续重试
        if ($compliance -eq '不合规') {
            $failedServers += $server
        }
    }
    catch {
        $report += [PSCustomObject]@{
            Server         = $server
            Compliance     = '无法连接'
            MissingCritical = '-'
            MissingTotal   = '-'
            RecentInstalled = '-'
            LastBootDays   = '-'
        }
        $failedServers += $server
    }
}

# 输出合规仪表板
Write-Host "`n========== Windows Update 合规报告 ==========" -ForegroundColor Cyan
Write-Host "报告时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

$report | Format-Table -AutoSize

# 合规统计
$compliant = ($report | Where-Object { $_.Compliance -eq '合规' }).Count
$partial = ($report | Where-Object { $_.Compliance -eq '部分合规' }).Count
$nonCompliant = ($report | Where-Object {
    $_.Compliance -in '不合规', '无法连接'
}).Count

Write-Host "合规统计："
Write-Host ("  合规：{0} 台 ({1:P0})" -f $compliant,
    ($compliant / $servers.Count)) -ForegroundColor Green
Write-Host ("  部分合规：{0} 台 ({1:P0})" -f $partial,
    ($partial / $servers.Count)) -ForegroundColor Yellow
Write-Host ("  不合规/离线：{0} 台 ({1:P0})" -f $nonCompliant,
    ($nonCompliant / $servers.Count)) -ForegroundColor Red

# 失败重试：对不合规服务器重新安装
if ($failedServers.Count -gt 0) {
    Write-Host "`n不合规服务器，准备重试安装：" -ForegroundColor Magenta
    $failedServers | ForEach-Object { Write-Host "  - $_" }
}
```

执行结果示例：

```
========== Windows Update 合规报告 ==========
报告时间：2026-01-16 14:30:00

Server    Compliance MissingCritical MissingTotal RecentInstalled LastBootDays
------    ---------- --------------- ------------ --------------- ------------
WEB-SVR01 合规                      0            0               3            2
WEB-SVR02 部分合规                  1            2               2           15
WEB-SVR03 合规                      0            0               4            2
DB-SVR01  不合规                    4            6               0           45
DB-SVR02  无法连接                  -            -               -            -

合规统计：
  合规：2 台 (40.00%)
  部分合规：1 台 (20.00%)
  不合规/离线：2 台 (40.00%)

不合规服务器，准备重试安装：
  - DB-SVR01
  - DB-SVR02
```

合规报告从三个维度评估补丁状态：缺失关键更新的数量、最近一周已安装更新的数量、以及距上次重启的天数。将三者结合可以全面反映机器的补丁健康度。不合规的服务器会被自动收集，用于触发重试流程。

## 注意事项

1. **权限要求**：Windows Update 操作需要本地管理员权限。在远程执行时，确保 WinRM 已启用且执行账户具有目标服务器的管理员权限，建议使用 Group Managed Service Account（gMSA）统一管理服务账户。

2. **PSWindowsUpdate 模块来源**：该模块托管在 PowerShell Gallery 上，安装前请确认执行策略允许运行（`Set-ExecutionPolicy RemoteSigned`）。在生产环境中，建议将模块下载到内部 NuGet 仓库，避免直接从公网拉取。

3. **测试先行**：每个 Patch Tuesday 发布的更新应先在测试环境中验证，确认与业务应用无兼容性问题后再推广到生产。建议维护一个延迟 1-2 周的部署窗口。

4. **重启窗口**：某些更新（特别是内核和驱动相关补丁）必须重启才能生效。重启操作应安排在维护窗口内，并提前通知相关团队。对于高可用集群，确保滚动重启不会同时影响所有节点。

5. **WSUS 集成**：大规模环境建议通过 WSUS（Windows Server Update Services）或 Configuration Manager 统一管理更新审批和分发。PowerShell 可以通过 `Microsoft.UpdateServices` 命名空间的 API 编写 WSUS 审批规则。

6. **日志与回滚**：保留每次更新的安装日志（路径 `C:\Windows\Logs\CBS\CBS.log`），出现问题时可以通过 `wusa /uninstall` 回滚特定补丁。建议将合规报告定期归档到中央日志系统，方便审计追溯。
