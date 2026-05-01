---
layout: post
date: 2025-12-02 08:00:00
title: "PowerShell 技能连载 - 流式输出与进度显示"
description: PowerTip of the Day - Streaming Output and Progress Display in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- progress
- streaming
- write-progress
- ui
---

_适用于 PowerShell 5.1 及以上版本_

## 背景

在执行长时间运行的 PowerShell 脚本时，用户最怕的不是等太久，而是不知道还要等多久。默认情况下，`foreach` 循环处理数百个对象时，控制台安静得仿佛脚本已经卡死。这种"黑盒体验"不仅让运维人员焦虑，也使得自动化流水线难以判断任务的实时进度。

PowerShell 提供了 `Write-Progress` cmdlet 来在控制台顶部显示进度条，配合 `$ProgressPreference` 变量可以精细控制进度显示的行为。与此同时，PowerShell 的管道流式输出机制允许你在处理数据的过程中逐条输出结果，而不必等到整个集合处理完毕。流式输出与进度显示相结合，就能构建出既高效又友好的脚本体验。

本文将从 `Write-Progress` 的基本用法出发，介绍 `$ProgressPreference` 的各种取值及效果，再通过实战案例演示如何在批量处理场景中同时实现流式输出和实时进度反馈。

## 基础：使用 Write-Progress 显示进度条

`Write-Progress` 是 PowerShell 内置的进度显示 cmdlet，它接受 `-Activity`（主标题）、`-Status`（当前状态文本）、`-PercentComplete`（百分比）和 `-CurrentOperation`（当前操作详情）等参数。下面通过一个模拟批量处理文件的场景来展示其基本用法。

```powershell
# 模拟批量处理文件并显示进度条
$fileList = @(
    "report-q1.xlsx"
    "report-q2.xlsx"
    "report-q3.xlsx"
    "report-q4.xlsx"
    "summary.docx"
    "budget-2025.xlsx"
    "forecast.csv"
    "inventory.json"
    "audit-trail.log"
    "config-backup.xml"
)

$total = $fileList.Count
$index = 0

foreach ($file in $fileList) {
    $index++
    $percent = [math]::Floor(($index / $total) * 100)

    Write-Progress -Activity "批量处理文件" `
        -Status "正在处理 ($index / $total): $file" `
        -PercentComplete $percent `
        -CurrentOperation "校验文件完整性"

    # 模拟处理耗时
    Start-Sleep -Milliseconds 300

    # 流式输出处理结果
    $result = [PSCustomObject]@{
        File      = $file
        Status    = "已完成"
        Size      = "$(Get-Random -Minimum 10 -Maximum 9999) KB"
        Timestamp = Get-Date -Format "HH:mm:ss"
    }
    Write-Output $result
}

# 关闭进度条
Write-Progress -Activity "批量处理文件" -Completed
```

执行结果示例：

```text
File              Status  Size     Timestamp
----              ------  ----     ---------
report-q1.xlsx    已完成   2341 KB  09:15:32
report-q2.xlsx    已完成   1876 KB  09:15:32
report-q3.xlsx    已完成   3210 KB  09:15:33
report-q4.xlsx    已完成   987 KB  09:15:33
summary.docx      已完成   5432 KB  09:15:34
budget-2025.xlsx  已完成   1567 KB  09:15:34
forecast.csv      已完成   8234 KB  09:15:34
inventory.json    已完成   456 KB  09:15:35
audit-trail.log   已完成   7891 KB  09:15:35
config-backup.xml 已完成   123 KB  09:15:35
```

这段代码展示了 `Write-Progress` 的核心用法。`-Activity` 定义进度条的主标题，`-Status` 显示当前正在处理哪一项，`-PercentComplete` 控制进度条的填充比例。注意最后的 `Write-Progress -Completed` 调用——它会清除控制台顶部的进度条，否则进度条会一直停留在屏幕上。每个文件处理完后立即通过 `Write-Output` 输出结果对象，实现了"边处理边输出"的流式效果。

## 进阶：使用 $ProgressPreference 控制进度行为

`$ProgressPreference` 是一个全局偏好变量，决定了 PowerShell 如何处理 `Write-Progress` 调用。它有四个有效取值：`Continue`（默认，显示进度条）、`SilentlyContinue`（不显示但继续执行）、`Ignore`（完全忽略进度输出）和 `Inquire`（每次显示进度前暂停询问用户）。不同的取值在不同场景下各有用处。

```powershell
# 展示 $ProgressPreference 四种取值的效果
$names = @("Alpha", "Beta", "Gamma", "Delta", "Epsilon")

function Invoke-HeavyTask {
    param([string[]]$Items, [string]$Mode)

    $prevPref = $ProgressPreference
    $ProgressPreference = $Mode

    $total = $Items.Count
    $index = 0

    foreach ($item in $Items) {
        $index++
        $percent = [math]::Floor(($index / $total) * 100)

        Write-Progress -Activity "模式: $Mode" `
            -Status "处理项: $item" `
            -PercentComplete $percent

        Start-Sleep -Milliseconds 200
        Write-Output "  [$Mode] 完成处理: $item"
    }

    Write-Progress -Activity "模式: $Mode" -Completed
    $ProgressPreference = $prevPref
}

# 模式 1: Continue（默认行为，显示进度条）
Write-Output "=== Continue 模式（显示进度条）==="
Invoke-HeavyTask -Items $names -Mode "Continue"

# 模式 2: SilentlyContinue（静默执行，不显示进度条）
Write-Output ""
Write-Output "=== SilentlyContinue 模式（隐藏进度条）==="
Invoke-HeavyTask -Items $names -Mode "SilentlyContinue"

# 模式 3: 在 CI/CD 中临时关闭进度条以提升性能
Write-Output ""
Write-Output "=== 模拟 CI/CD 环境：批量安装模块 ===="
$modules = @("Pester", "PSScriptAnalyzer", "platyPS", "InvokeBuild")
$ProgressPreference = "SilentlyContinue"

foreach ($mod in $modules) {
    Write-Output "  正在安装模块: $mod ... (模拟)"
    Start-Sleep -Milliseconds 150
    Write-Output "  完成: $mod"
}

$ProgressPreference = "Continue"

Write-Output ""
Write-Output "所有模式演示完毕"
```

执行结果示例：

```text
=== Continue 模式（显示进度条）===
  [Continue] 完成处理: Alpha
  [Continue] 完成处理: Beta
  [Continue] 完成处理: Gamma
  [Continue] 完成处理: Delta
  [Continue] 完成处理: Epsilon

=== SilentlyContinue 模式（隐藏进度条）===
  [SilentlyContinue] 完成处理: Alpha
  [SilentlyContinue] 完成处理: Beta
  [SilentlyContinue] 完成处理: Gamma
  [SilentlyContinue] 完成处理: Delta
  [SilentlyContinue] 完成处理: Epsilon

=== 模拟 CI/CD 环境：批量安装模块 ====
  正在安装模块: Pester ... (模拟)
  完成: Pester
  正在安装模块: PSScriptAnalyzer ... (模拟)
  完成: PSScriptAnalyzer
  正在安装模块: platyPS ... (模拟)
  完成: platyPS
  正在安装模块: InvokeBuild ... (模拟)
  完成: InvokeBuild

所有模式演示完毕
```

这段代码的关键点在于函数内部先保存 `$ProgressPreference` 的原始值，执行完毕后再恢复。这种"保存-修改-恢复"模式可以避免偏好变量被永久修改后影响后续代码。`SilentlyContinue` 模式在 CI/CD 自动化场景中特别重要——`Write-Progress` 的控制台渲染本身有性能开销，在处理数千个对象时可能使脚本总耗时增加 20% 以上。关闭进度条可以显著提升批量操作的执行速度。

## 实战：带子进度和 ETA 的多层进度显示

当任务包含嵌套结构时（例如处理多个服务器，每台服务器上又有多个检查项），单层进度条无法清晰表达层次关系。`Write-Progress` 支持 `-ParentId` 参数来创建嵌套进度条，同时我们可以手动计算预估剩余时间（ETA），让进度信息更加完整。下面模拟一个多服务器安全巡检的场景。

```powershell
# 多层嵌套进度条 + ETA 预估
$servers = @(
    @{ Name = "WEB-01"; IP = "192.168.1.10" }
    @{ Name = "WEB-02"; IP = "192.168.1.11" }
    @{ Name = "DB-01";  IP = "192.168.1.20" }
    @{ Name = "DB-02";  IP = "192.168.1.21" }
    @{ Name = "CACHE-01"; IP = "192.168.1.30" }
)

$checks = @("端口扫描", "服务状态", "磁盘空间", "内存使用", "安全补丁")

$startTime = Get-Date
$serverIndex = 0
$totalServers = $servers.Count
$allResults = @()

foreach ($server in $servers) {
    $serverIndex++
    $serverPercent = [math]::Floor(($serverIndex / $totalServers) * 100)
    $elapsed = (Get-Date) - $startTime
    $avgPerServer = $elapsed.TotalSeconds / $serverIndex
    $remaining = [math]::Ceiling($avgPerServer * ($totalServers - $serverIndex))
    $eta = (Get-Date).AddSeconds($remaining).ToString("HH:mm:ss")

    $statusText = "服务器 $serverIndex/$totalServers - 预计剩余 ${remaining}s (ETA: $eta)"

    # 父进度条
    Write-Progress -Id 1 -Activity "服务器安全巡检" `
        -Status $statusText `
        -PercentComplete $serverPercent

    $checkIndex = 0
    $totalChecks = $checks.Count
    $serverHealthy = $true

    foreach ($check in $checks) {
        $checkIndex++
        $checkPercent = [math]::Floor(($checkIndex / $totalChecks) * 100)

        # 子进度条（ParentId = 1）
        Write-Progress -Id 2 -ParentId 1 -Activity "检查: $check" `
            -Status "$($server.Name) ($($server.IP)) - 步骤 $checkIndex/$totalChecks" `
            -PercentComplete $checkPercent

        # 模拟检查结果
        $isPass = (Get-Random -Maximum 10) -gt 2
        if (-not $isPass) {
            $serverHealthy = $false
        }

        $result = [PSCustomObject]@{
            Server   = $server.Name
            IP       = $server.IP
            Check    = $check
            Result   = if ($isPass) { "通过" } else { "告警" }
            Detail   = if ($isPass) { "正常" } else { "需要关注" }
            CheckTime = Get-Date -Format "HH:mm:ss"
        }
        $allResults += $result

        Start-Sleep -Milliseconds 150
    }

    # 关闭子进度条
    Write-Progress -Id 2 -ParentId 1 -Activity "检查完毕" -Completed
}

# 关闭父进度条
Write-Progress -Id 1 -Activity "服务器安全巡检" -Completed

# 输出汇总报告
Write-Output "==========================================="
Write-Output "  服务器安全巡检报告"
Write-Output "  扫描时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "==========================================="
Write-Output ""

foreach ($result in $allResults) {
    $mark = if ($result.Result -eq "通过") { "[OK]" } else { "[!!]" }
    Write-Output "  $mark $($result.Server) | $($result.Check) | $($result.Detail)"
}

Write-Output ""
$passCount = @($allResults | Where-Object { $_.Result -eq "通过" }).Count
$warnCount = @($allResults | Where-Object { $_.Result -eq "告警" }).Count
Write-Output "-------------------------------------------"
Write-Output "  总计: $($allResults.Count) 项检查"
Write-Output "  通过: $passCount 项"
Write-Output "  告警: $warnCount 项"
Write-Output "  通过率: $([math]::Floor($passCount / $allResults.Count * 100))%"
Write-Output "-------------------------------------------"
```

执行结果示例：

```text
===========================================
  服务器安全巡检报告
  扫描时间: 2025-12-02 09:30:45
===========================================

  [OK] WEB-01 | 端口扫描 | 正常
  [OK] WEB-01 | 服务状态 | 正常
  [OK] WEB-01 | 磁盘空间 | 正常
  [OK] WEB-01 | 内存使用 | 正常
  [OK] WEB-01 | 安全补丁 | 正常
  [OK] WEB-02 | 端口扫描 | 正常
  [!!] WEB-02 | 服务状态 | 需要关注
  [OK] WEB-02 | 磁盘空间 | 正常
  [OK] WEB-02 | 内存使用 | 正常
  [OK] WEB-02 | 安全补丁 | 正常
  [OK] DB-01  | 端口扫描 | 正常
  [OK] DB-01  | 服务状态 | 正常
  [!!] DB-01  | 磁盘空间 | 需要关注
  [OK] DB-01  | 内存使用 | 正常
  [!!] DB-01  | 安全补丁 | 需要关注
  [OK] DB-02  | 端口扫描 | 正常
  [OK] DB-02  | 服务状态 | 正常
  [OK] DB-02  | 磁盘空间 | 正常
  [OK] DB-02  | 内存使用 | 正常
  [OK] DB-02  | 安全补丁 | 正常
  [OK] CACHE-01 | 端口扫描 | 正常
  [!!] CACHE-01 | 服务状态 | 需要关注
  [OK] CACHE-01 | 磁盘空间 | 正常
  [OK] CACHE-01 | 内存使用 | 正常
  [OK] CACHE-01 | 安全补丁 | 正常

-------------------------------------------
  总计: 25 项检查
  通过: 21 项
  告警: 4 项
  通过率: 84%
-------------------------------------------
```

这段代码使用了 `Write-Progress` 的 `-Id` 和 `-ParentId` 参数来创建两层嵌套进度条。外层进度条（Id=1）显示服务器级别的整体进度和 ETA 预估，内层进度条（Id=2，ParentId=1）显示当前服务器上各项检查的进度。ETA 的计算基于已用时间和已完成数量的平均值：`$avgPerServer = $elapsed.TotalSeconds / $serverIndex`，再乘以剩余数量得到预估秒数。注意每个服务器处理完毕后必须用 `-Completed` 关闭子进度条，否则子进度条会叠加显示。

## 注意事项

1. **`Write-Progress` 在重定向输出时会被忽略**。当脚本输出被重定向到文件（如 `script.ps1 > output.txt`）或在后台作业（`Start-Job`）中执行时，`Write-Progress` 调用不会产生任何可见效果，但调用本身仍然存在性能开销。在这些场景下，应主动将 `$ProgressPreference` 设为 `SilentlyContinue` 以避免无谓的进度条渲染。

2. **进度条会显著降低大量迭代的性能**。`Write-Progress` 每次调用都会触发控制台 UI 更新，当循环次数达到数千甚至数万时，进度条本身的开销可能超过实际业务逻辑。建议在循环中加入计数器，每处理 N 条记录才更新一次进度条（例如每 100 条更新一次），而不是每条记录都调用 `Write-Progress`。

3. **`-ParentId` 嵌套层级不宜过深**。PowerShell 控制台最多支持两层进度条（父和子），PowerShell 7 的终端理论上支持更多层，但超过三层后 UI 会变得混乱且难以阅读。如果任务确实有多层结构，建议只在最外层和当前处理层显示进度，中间层级通过 `-Status` 文本信息来表达。

4. **`$ProgressPreference` 的作用域遵循 PowerShell 作用域规则**。在函数内修改 `$ProgressPreference` 默认只影响当前函数作用域，不会传播到调用者。但如果在脚本顶层修改，则会影响该脚本内所有后续代码。最佳实践是在函数内采用"保存-修改-恢复"模式，在脚本开头统一设置则用 `try/finally` 确保异常时也能恢复原始值。

5. **`Write-Progress -SecondsRemaining` 参数可以替代手动 ETA 计算**。除了手动计算预估时间外，`Write-Progress` 自带 `-SecondsRemaining` 参数，PowerShell 会将其显示在进度条右侧。但这个参数只是你传入的一个数值，PowerShell 不会自动计算——你仍然需要自己根据已用时间和已完成比例来推算剩余秒数。

6. **在 VS Code 集成终端中进度条显示可能异常**。VS Code 的 PowerShell 集成终端对 VT100 转义序列的支持有限，`Write-Progress` 可能表现为闪烁或不完整的进度条。在开发调试阶段，建议直接在 Windows Terminal 或 PowerShell ISE 中运行脚本以获得最佳进度条显示效果，或者将 `$ProgressPreference` 设为 `SilentlyContinue` 改用 `Write-Host` 输出简洁的文本进度信息。
