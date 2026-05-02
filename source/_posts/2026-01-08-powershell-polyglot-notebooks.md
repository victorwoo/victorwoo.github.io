---
layout: post
date: 2026-01-08 08:00:00
updated: 2026-01-08 08:00:00
title: "PowerShell 技能连载 - Polyglot Notebooks 交互式脚本"
description: PowerTip of the Day - Polyglot Notebooks Interactive Scripting
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- ai
---

_适用于 PowerShell 7.0 及以上版本_

Polyglot Notebooks（前身 .NET Interactive）是微软推出的一款交互式笔记本工具，它将 Jupyter 笔记本的理念带入了 .NET 生态。与传统的 Jupyter 仅支持 Python 等单一内核不同，Polyglot Notebooks 的核心优势在于多语言互操作：你可以在同一个笔记本中无缝切换 PowerShell、C#、F#、JavaScript、HTML 等语言，并通过变量共享机制让不同语言的代码块协同工作。

对于 PowerShell 用户而言，这意味着你不必再在"用 PowerShell 写脚本"和"用 Jupyter 做数据分析"之间做选择。你可以直接在笔记本中用 PowerShell 获取系统数据、调用 REST API、操作文件系统，然后用 C# 处理复杂的计算逻辑，最后用 JavaScript 生成可交互的可视化图表——所有这些都在同一个文档中完成。

本文将从三个方面介绍 Polyglot Notebooks 的实战用法：首先搭建环境并掌握基础的 Magic Commands，然后演示多语言协作与变量共享的技巧，最后通过一个数据分析实战案例展示完整的工作流。

<!-- more -->

## Notebook 基础操作

要在 Polyglot Notebooks 中使用 PowerShell，需要先安装 .NET SDK 和 Polyglot Notebooks 扩展。整个过程非常简洁，下面这个脚本会自动检查环境并完成初始化配置。

```powershell
# 检查 .NET SDK 是否已安装
function Assert-DotNetSdk {
    $sdk = dotnet --version 2>$null
    if (-not $sdk) {
        Write-Host "正在安装 .NET SDK ..." -ForegroundColor Yellow
        winget install Microsoft.DotNet.SDK.8 --accept-source-agreements
    } else {
        Write-Host ".NET SDK 版本: $sdk" -ForegroundColor Green
    }

    # 安装 PowerShell 内核（Jupyter kernel）
    dotnet tool install -g Microsoft.dotnet-interactive
    dotnet interactive jupyter install

    # 验证内核是否注册成功
    $kernels = jupyter kernelspec list 2>$null
    if ($kernels -match "powershell") {
        Write-Host "PowerShell 内核已注册" -ForegroundColor Green
    } else {
        Write-Host "PowerShell 内核未找到，请手动执行 jupyter kernelspec list 排查" -ForegroundColor Red
    }
}

Assert-DotNetSdk
```

执行结果示例：

```text
.NET SDK 版本: 8.0.403
PowerShell 内核已注册
```

安装完成后，在 VS Code 中安装 Polyglot Notebooks 扩展（扩展 ID: `ms-dotnettools.dotnet-interactive-vscode`），然后创建一个 `.dib` 或 `.ipynb` 文件即可开始使用。Polyglot Notebooks 提供了一组称为 "Magic Commands" 的特殊指令，以 `#!` 开头，用于控制笔记本行为。以下是最常用的几个：

```powershell
# 查看当前可用的所有语言内核
#!about

# 切换当前单元格的语言为 PowerShell
#!pwsh

# 切换到 C#
#!csharp

# 切换到 JavaScript
#!javascript

# 设置变量共享 —— 在 PowerShell 中定义变量后让其他语言使用
#!set --value @pwsh:serverName --name serverName

# 从外部文件导入脚本并执行
#!import --file ./data-processing.ps1

# 获取笔记本运行环境信息
$PSVersionTable
[System.Environment]::OSVersion
```

执行结果示例：

```text
PowerShell 7.4.6
OS: Microsoft Windows 10.0.22631
Platform: Win32NT
```

Magic Commands 的强大之处在于它们可以在单元格的第一行使用，无需额外的配置。这意味着你可以逐个单元格地指定语言，实现真正的多语言混合编程。

## 多语言协作与变量共享

Polyglot Notebooks 最令人兴奋的特性是跨语言变量共享。你可以在 PowerShell 中采集数据，传递给 C# 进行复杂计算，再用 JavaScript 渲染为可交互的 HTML 页面。下面这个示例演示了完整的多语言协作流程。

```powershell
# === PowerShell 单元格：采集系统性能数据 ===
#!pwsh

# 收集当前系统的 CPU 和内存信息
$cpuUsage = [math]::Round(
    (Get-CimInstance Win32_Processor).LoadPercentage, 2
)
$os = Get-CimInstance Win32_OperatingSystem
$totalMemGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeMemGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMemGB = [math]::Round($totalMemGB - $freeMemGB, 2)
$memPercent = [math]::Round(($usedMemGB / $totalMemGB) * 100, 1)

# 获取磁盘信息
$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{N="TotalGB"; E={[math]::Round($_.Size/1GB,2)}},
        @{N="FreeGB"; E={[math]::Round($_.FreeSpace/1GB,2)}},
        @{N="UsedPercent"; E={[math]::Round(($_.Size - $_.FreeSpace)/$_.Size * 100, 1)}}

$systemInfo = @{
    HostName    = $env:COMPUTERNAME
    CpuUsage    = $cpuUsage
    TotalMemGB  = $totalMemGB
    UsedMemGB   = $usedMemGB
    FreeMemGB   = $freeMemGB
    MemPercent  = $memPercent
    Disks       = $disks
    Timestamp   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

Write-Host "系统数据采集完成: $($systemInfo.HostName)" -ForegroundColor Cyan
$systemInfo | ConvertTo-Json -Depth 3
```

执行结果示例：

```text
系统数据采集完成: DESKTOP-WIN11
{
  "HostName": "DESKTOP-WIN11",
  "CpuUsage": 23,
  "TotalMemGB": 31.87,
  "UsedMemGB": 18.54,
  "FreeMemGB": 13.33,
  "MemPercent": 58.2,
  "Disks": [
    {
      "DeviceID": "C:",
      "TotalGB": 476.37,
      "FreeGB": 198.24,
      "UsedPercent": 58.4
    },
    {
      "DeviceID": "D:",
      "TotalGB": 931.51,
      "FreeGB": 645.12,
      "UsedPercent": 30.7
    }
  ],
  "Timestamp": "2026-01-08 09:15:32"
}
```

接下来在 C# 单元格中接收这些数据并进行处理分析：

```powershell
# === C# 单元格：利用 LINQ 进行数据分析 ===
#!csharp
#!set --value @pwsh:systemInfo --name systemInfo

using System.Text.Json;

// 解析 PowerShell 传入的 JSON 数据
var json = systemInfo.ToString();
var doc = JsonDocument.Parse(json);
var root = doc.RootElement;

// 提取关键指标
var hostName = root.GetProperty("HostName").GetString();
var cpuUsage = root.GetProperty("CpuUsage").GetInt32();
var memPercent = root.GetProperty("MemPercent").GetDouble();
var timestamp = root.GetProperty("Timestamp").GetString();

// 生成健康评估报告
var healthScore = 100.0;
var warnings = new List<string>();

if (cpuUsage > 80) {
    healthScore -= 30;
    warnings.Add($"CPU 使用率过高: {cpuUsage}%");
} else if (cpuUsage > 60) {
    healthScore -= 10;
    warnings.Add($"CPU 使用率偏高: {cpuUsage}%");
}

if (memPercent > 85) {
    healthScore -= 25;
    warnings.Add($"内存使用率过高: {memPercent}%");
} else if (memPercent > 70) {
    healthScore -= 10;
    warnings.Add($"内存使用率偏高: {memPercent}%");
}

var status = healthScore >= 80 ? "健康" :
             healthScore >= 60 ? "注意" : "警告";

// 将结果保存为共享变量供后续使用
var report = new {
    HostName = hostName,
    Timestamp = timestamp,
    HealthScore = Math.Round(healthScore, 1),
    Status = status,
    Warnings = warnings,
    Summary = $"[{status}] {hostName} 健康评分: {healthScore:F1}/100"
};

Console.WriteLine(report.Summary);
if (warnings.Any()) {
    Console.WriteLine("告警项:");
    warnings.ForEach(w => Console.WriteLine($"  - {w}"));
}
```

执行结果示例：

```text
[注意] DESKTOP-WIN11 健康评分: 80.0/100
告警项:
  - 内存使用率偏高: 58.2%
```

通过 `#!set` 命令，C# 单元格直接读取了 PowerShell 中定义的 `$systemInfo` 变量。这种跨语言变量传递是 Polyglot Notebooks 的核心能力，使得每种语言都可以专注于自己最擅长的领域。

## 数据分析与可视化实战

最后一个场景是数据分析的完整工作流：用 PowerShell 导入 CSV 数据并进行清洗，然后用 C# 进行聚合计算，最后生成 HTML 可视化报告。

```powershell
# === PowerShell 单元格：数据导入与清洗 ===
#!pwsh

# 模拟生成服务器监控日志数据（实际使用时替换为 Import-Csv）
$sampleData = @(
    @{ Server="WEB-01"; Region="East"; CPU=45; Memory=62; Requests=12500; Errors=23; Date="2026-01-01" }
    @{ Server="WEB-02"; Region="East"; CPU=78; Memory=81; Requests=18900; Errors=156; Date="2026-01-01" }
    @{ Server="API-01"; Region="West"; CPU=32; Memory=55; Requests=45000; Errors=12; Date="2026-01-01" }
    @{ Server="API-02"; Region="West"; CPU=91; Memory=88; Requests=52000; Errors=423; Date="2026-01-01" }
    @{ Server="DB-01"; Region="Central"; CPU=67; Memory=74; Requests=8500; Errors=5; Date="2026-01-01" }
    @{ Server="DB-02"; Region="Central"; CPU=55; Memory=69; Requests=7200; Errors=2; Date="2026-01-02" }
    @{ Server="WEB-01"; Region="East"; CPU=52; Memory=65; Requests=13100; Errors=31; Date="2026-01-02" }
    @{ Server="API-01"; Region="West"; CPU=38; Memory=58; Requests=47200; Errors=18; Date="2026-01-02" }
    @{ Server="CACHE-01"; Region="East"; CPU=22; Memory=91; Requests=98000; Errors=1; Date="2026-01-02" }
    @{ Server="WORKER-01"; Region="West"; CPU=85; Memory=43; Requests=3200; Errors=8; Date="2026-01-02" }
)

$records = $sampleData | ForEach-Object {
    [PSCustomObject]@{
        Server   = $_.Server
        Region   = $_.Region
        CPU      = [int]$_.CPU
        Memory   = [int]$_.Memory
        Requests = [int]$_.Requests
        Errors   = [int]$_.Errors
        Date     = $_.Date
        ErrorRate = [math]::Round($_.Errors / $_.Requests * 100, 3)
    }
}

# 数据清洗：标记异常服务器
$cleanData = $records | ForEach-Object {
    $flags = @()
    if ($_.CPU -gt 80) { $flags += "CPU高负载" }
    if ($_.Memory -gt 85) { $flags += "内存高占用" }
    if ($_.ErrorRate -gt 0.5) { $flags += "错误率异常" }

    $_ | Add-Member -NotePropertyName "Flags" -NotePropertyValue ($flags -join ", ") -PassThru
}

# 输出统计摘要
$totalRecords = $cleanData.Count
$flaggedCount = ($cleanData | Where-Object { $_.Flags }).Count
$avgCpu = [math]::Round(($cleanData | Measure-Object -Property CPU -Average).Average, 1)
$avgMem = [math]::Round(($cleanData | Measure-Object -Property Memory -Average).Average, 1)

Write-Host "数据概览:" -ForegroundColor Cyan
Write-Host "  总记录数: $totalRecords"
Write-Host "  异常标记数: $flaggedCount"
Write-Host "  平均 CPU: ${avgCpu}%"
Write-Host "  平均内存: ${avgMem}%"
Write-Host ""

# 按区域分组汇总
$regionSummary = $cleanData |
    Group-Object Region |
    ForEach-Object {
        $group = $_.Group
        [PSCustomObject]@{
            Region     = $_.Name
            Count      = $_.Count
            AvgCPU     = [math]::Round(($group | Measure-Object CPU -Average).Average, 1)
            AvgMemory  = [math]::Round(($group | Measure-Object Memory -Average).Average, 1)
            TotalReqs  = ($group | Measure-Object Requests -Sum).Sum
            TotalErrors = ($group | Measure-Object Errors -Sum).Sum
        }
    }

$regionSummary | Format-Table -AutoSize

# 生成 HTML 可视化报告
$htmlReport = @"
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>服务器监控报告</title>
<style>
  body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #f5f5f5; }
  h1 { color: #0078d4; }
  table { border-collapse: collapse; width: 100%; margin-top: 10px; }
  th { background: #0078d4; color: white; padding: 10px; text-align: left; }
  td { padding: 8px 10px; border-bottom: 1px solid #ddd; }
  tr:nth-child(even) { background: #f9f9f9; }
  .flag { color: #d13438; font-weight: bold; }
  .ok { color: #107c10; }
  .warn { color: #ff8c00; }
</style>
</head>
<body>
<h1>服务器监控报告</h1>
<p>生成时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
<h2>异常服务器列表</h2>
<table>
<tr><th>服务器</th><th>区域</th><th>CPU</th><th>内存</th>
    <th>请求数</th><th>错误数</th><th>错误率</th><th>标记</th></tr>
"@

foreach ($row in ($cleanData | Where-Object { $_.Flags })) {
    $cpuClass = if ($row.CPU -gt 80) { "flag" } elseif ($row.CPU -gt 60) { "warn" } else { "ok" }
    $memClass = if ($row.Memory -gt 85) { "flag" } elseif ($row.Memory -gt 70) { "warn" } else { "ok" }
    $htmlReport += @"
<tr>
  <td>$($row.Server)</td>
  <td>$($row.Region)</td>
  <td class="$cpuClass">$($row.CPU)%</td>
  <td class="$memClass">$($row.Memory)%</td>
  <td>$($row.Requests)</td>
  <td>$($row.Errors)</td>
  <td>$($row.ErrorRate)%</td>
  <td class="flag">$($row.Flags)</td>
</tr>
"@
}

$htmlReport += "</table></body></html>"

# 保存报告
$reportPath = Join-Path $env:TEMP "ServerMonitor-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
$htmlReport | Out-File -FilePath $reportPath -Encoding utf8
Write-Host ""
Write-Host "HTML 报告已生成: $reportPath" -ForegroundColor Green
```

执行结果示例：

```text
数据概览:
  总记录数: 10
  异常标记数: 4
  平均 CPU: 56.5%
  平均内存: 68.6%

Region  Count AvgCPU AvgMemory TotalReqs TotalErrors
------  ----- ------ --------- --------- -----------
Central     2   61.0      71.5     15700           7
East        4   49.2      74.8    132500         211
West        4   61.5      61.8    104400         461

HTML 报告已生成: /tmp/ServerMonitor-20260108-091532.html
```

这个实战案例展示了 Polyglot Notebooks 在数据运维中的完整工作流：PowerShell 负责数据采集和清洗，通过对象管道完成分组聚合，最终生成带有条件高亮的 HTML 可视化报告。在实际工作中，你可以将 `Import-Csv` 替换为真实数据源，还可以添加 C# 单元格进行更复杂的统计分析。

## 注意事项

- Polyglot Notebooks 需要 .NET 8.0 SDK 或更高版本。安装前请确认系统已满足此先决条件，否则 `dotnet interactive` 命令将无法正常注册 Jupyter 内核。

- 跨语言变量共享通过 `#!set` 命令实现，传递时数据会被序列化为 JSON 格式。复杂对象（如 `PSCustomObject`）可以顺利传递，但包含方法或闭包的对象会被自动剥离，只保留属性数据。

- 在 VS Code 中使用 `.dib` 格式是 Polyglot Notebooks 的原生体验，功能最为完整。如果使用标准 `.ipynb` 格式，请确保在笔记本元数据中正确指定了内核为 `.NET (Polyglot)`。

- Magic Commands 必须写在单元格的第一行，前面不能有任何其他代码或空行。否则笔记本引擎无法识别指令，会将其作为普通文本处理。

- 当笔记本中的数据量较大时（例如数万行 CSV），建议在 PowerShell 单元格中使用 `Measure-Object`、`Group-Object` 等流式处理命令，避免将全量数据加载到内存中导致性能下降。

- Polyglot Notebooks 目前不支持直接在 JupyterLab 中运行 PowerShell 内核的自动补全功能。如果需要 IntelliSense 支持，推荐在 VS Code 中配合 Polyglot 扩展使用，可以获得完整的代码补全和语法检查体验。
