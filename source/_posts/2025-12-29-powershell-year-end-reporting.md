---
layout: post
date: 2025-12-29 08:00:00
updated: 2025-12-29 08:00:00
title: "PowerShell 技能连载 - 年终报告自动生成"
description: PowerTip of the Day - Year-End Report Auto Generation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- reporting
- html
- charts
- automation
---

_适用于 PowerShell 5.1 及以上版本_

每到年底，IT 部门都需要向管理层提交各类运维报告：服务器可用性统计、安全事件汇总、资源使用趋势分析、成本核算等。这些数据往往分散在事件日志、CSV 文件、数据库、REST API 等多个来源中，手动汇总整理费时费力，而且容易出现遗漏和统计口径不一致的问题。

借助 PowerShell 强大的数据采集与处理能力，我们可以编写脚本自动从多个数据源采集原始数据，按照预定义的维度进行聚合统计，再结合 HTML 模板引擎生成包含表格、图表和趋势线的高质量报告。整个过程无需手动干预，一条命令即可产出一份数据完整、格式专业的年终总结。

本文将围绕多源数据采集与聚合、HTML 报告渲染（含内联图表）、以及报告分发与归档三个核心环节，展示如何用 PowerShell 构建一套可复用的年终报告自动生成流水线。

## 多源数据采集与聚合

年终报告的第一步是从多个数据源采集原始数据并进行统一聚合。下面的脚本演示如何从 Windows 事件日志、CSV 日志文件和自定义数据结构中提取关键指标，生成结构化的年度汇总数据集。

```powershell
function Get-YearEndReportData {
    <#
    .SYNOPSIS
    从多个数据源采集并聚合年终报告所需的数据
    .PARAMETER Year
    统计年份，默认为当前年份
    #>
    param(
        [int]$Year = (Get-Date).Year
    )

    $startDate = Get-Date -Year $Year -Month 1 -Day 1
    $endDate = Get-Date -Year $Year -Month 12 -Day 31

    # ---- 1. 从 Windows 事件日志采集安全事件统计 ----
    $securityEvents = @()
    try {
        $logonEvents = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            Id = 4624, 4625
            StartTime = $startDate
            EndTime = $endDate
        } -ErrorAction SilentlyContinue

        $logonSuccess = ($logonEvents | Where-Object Id -eq 4624 | Measure-Object).Count
        $logonFailed = ($logonEvents | Where-Object Id -eq 4625 | Measure-Object).Count

        $securityEvents = [PSCustomObject]@{
            成功登录 = $logonSuccess
            失败登录 = $logonFailed
            登录失败率 = if ($logonSuccess + $logonFailed -gt 0) {
                [math]::Round($logonFailed / ($logonSuccess + $logonFailed) * 100, 2)
            } else { 0 }
        }
    } catch {
        $securityEvents = [PSCustomObject]@{
            成功登录 = 0; 失败登录 = 0; 登录失败率 = 0
        }
    }

    # ---- 2. 从系统事件日志采集可用性数据 ----
    $rebootEvents = Get-WinEvent -FilterHashtable @{
        LogName = 'System'
        Id = 1074, 6008
        StartTime = $startDate
        EndTime = $endDate
    } -ErrorAction SilentlyContinue

    $plannedReboots = ($rebootEvents | Where-Object Id -eq 1074 | Measure-Object).Count
    $unexpectedShutdowns = ($rebootEvents | Where-Object Id -eq 6008 | Measure-Object).Count

    # ---- 3. 从 CSV 日志文件采集资源使用数据 ----
    $csvPath = ".\server-metrics-$Year.csv"
    $monthlyStats = @()

    if (Test-Path $csvPath) {
        $metrics = Import-Csv -Path $csvPath -Encoding UTF8
        $monthlyStats = $metrics | Group-Object { $_.Date.Substring(0, 7) } | ForEach-Object {
            $avgCpu = [math]::Round(($_.Group | Measure-Object -Property CPU -Average).Average, 1)
            $avgMem = [math]::Round(($_.Group | Measure-Object -Property Memory -Average).Average, 1)
            $maxDisk = [math]::Round(($_.Group | Measure-Object -Property DiskUsage -Maximum).Maximum, 1)

            [PSCustomObject]@{
                月份 = $_.Name
                平均CPU使用率 = "$avgCpu%"
                平均内存使用率 = "$avgMem%"
                最大磁盘使用率 = "$maxDisk%"
            }
        }
    } else {
        # 模拟数据用于演示
        1..12 | ForEach-Object {
            $month = "{0:D2}" -f $_
            $monthlyStats += [PSCustomObject]@{
                月份 = "$Year-$month"
                平均CPU使用率 = "$([math]::Round((Get-Random -Min 25 -Max 75) + (Get-Random -Min 1 -Max 99) / 100, 1))%"
                平均内存使用率 = "$([math]::Round((Get-Random -Min 40 -Max 85) + (Get-Random -Min 1 -Max 99) / 100, 1))%"
                最大磁盘使用率 = "$([math]::Round((Get-Random -Min 50 -Max 90) + (Get-Random -Min 1 -Max 99) / 100, 1))%"
            }
        }
    }

    # ---- 4. 汇总输出 ----
    [PSCustomObject]@{
        报告年份 = $Year
        数据周期 = "$($startDate.ToString('yyyy-MM-dd')) 至 $($endDate.ToString('yyyy-MM-dd'))"
        安全事件统计 = $securityEvents
        计划重启次数 = $plannedReboots
        非计划关机次数 = $unexpectedShutdowns
        月度资源统计 = $monthlyStats
        生成时间 = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

# 采集 2025 年度报告数据
$reportData = Get-YearEndReportData -Year 2025

Write-Host "报告年份: $($reportData.报告年份)" -ForegroundColor Cyan
Write-Host "数据周期: $($reportData.数据周期)" -ForegroundColor Cyan
Write-Host "安全事件: 成功登录 $($reportData.安全事件统计.成功登录) 次, 失败登录 $($reportData.安全事件统计.失败登录) 次" -ForegroundColor Yellow
Write-Host "月度数据条数: $($reportData.月度资源统计.Count)" -ForegroundColor Green
```

执行结果示例：

```
报告年份: 2025
数据周期: 2025-01-01 至 2025-12-31
安全事件: 成功登录 15238 次, 失败登录 347 次
月度数据条数: 12
```

## 生成 HTML 报告（含 CSS 样式与内联图表）

数据采集完成后，下一步是将结构化数据渲染为美观的 HTML 报告。下面的脚本使用 PowerShell 的 here-string 构建 HTML 模板，内嵌 CSS 样式，并通过纯 CSS 的柱状图直观展示月度趋势数据。

```powershell
function New-YearEndHtmlReport {
    <#
    .SYNOPSIS
    将年度报告数据渲染为带样式和内联图表的 HTML 文件
    .PARAMETER ReportData
    由 Get-YearEndReportData 返回的数据对象
    .PARAMETER OutputPath
    HTML 报告输出路径
    #>
    param(
        [Parameter(Mandatory)]
        $ReportData,
        [string]$OutputPath = ".\YearEnd-Report-$($ReportData.报告年份).html"
    )

    # 构建月度资源表格行
    $tableRows = $ReportData.月度资源统计 | ForEach-Object {
        "      <tr><td>$($_.月份)</td><td>$($_.平均CPU使用率)</td><td>$($_.平均内存使用率)</td><td>$($_.最大磁盘使用率)</td></tr>"
    }
    $tableRowsHtml = $tableRows -join "`n"

    # 构建简易柱状图（纯 CSS 实现，无需 JavaScript 库）
    $chartBars = $ReportData.月度资源统计 | ForEach-Object {
        $cpuVal = [int]($_.平均CPU使用率 -replace '%', '')
        $barHeight = $cpuVal * 2
        $label = $_.月份.Substring(5)
        "        <div class='bar-col'><div class='bar' style='height:${barHeight}px'></div><div class='bar-label'>$label</div></div>"
    }
    $chartHtml = $chartBars -join "`n"

    $sec = $ReportData.安全事件统计

    # HTML 报告内容
    $htmlContent = @"
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>IT 运维年度报告 - $($ReportData.报告年份)</title>
<style>
  body { font-family: "Microsoft YaHei", "Segoe UI", sans-serif; margin: 40px; background: #f5f7fa; color: #333; }
  h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
  h2 { color: #2c3e50; margin-top: 30px; }
  .summary-box { display: flex; gap: 20px; margin: 20px 0; flex-wrap: wrap; }
  .stat-card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); min-width: 200px; }
  .stat-card h3 { margin: 0 0 10px 0; color: #7f8c8d; font-size: 14px; }
  .stat-card .value { font-size: 28px; font-weight: bold; color: #2c3e50; }
  table { border-collapse: collapse; width: 100%; background: white; box-shadow: 0 2px 8px rgba(0,0,0,0.1); border-radius: 8px; overflow: hidden; }
  th { background: #3498db; color: white; padding: 12px; text-align: left; }
  td { padding: 10px 12px; border-bottom: 1px solid #ecf0f1; }
  tr:hover { background: #ebf5fb; }
  .chart-container { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); margin: 20px 0; }
  .chart-area { display: flex; align-items: flex-end; gap: 8px; height: 200px; padding: 10px 0; }
  .bar-col { display: flex; flex-direction: column; align-items: center; flex: 1; }
  .bar { background: linear-gradient(to top, #3498db, #2ecc71); border-radius: 4px 4px 0 0; width: 100%; max-width: 40px; }
  .bar-label { font-size: 11px; margin-top: 5px; color: #7f8c8d; }
  .footer { margin-top: 30px; color: #95a5a6; font-size: 12px; text-align: center; }
</style>
</head>
<body>
  <h1>IT 运维年度报告 - $($ReportData.报告年份)</h1>
  <p>报告周期：$($ReportData.数据周期) &nbsp;|&nbsp; 生成时间：$($ReportData.生成时间)</p>

  <h2>核心指标概览</h2>
  <div class="summary-box">
    <div class="stat-card"><h3>成功登录</h3><div class="value">$($sec.成功登录)</div></div>
    <div class="stat-card"><h3>失败登录</h3><div class="value" style="color:#e74c3c">$($sec.失败登录)</div></div>
    <div class="stat-card"><h3>登录失败率</h3><div class="value">$($sec.登录失败率)%</div></div>
    <div class="stat-card"><h3>计划重启</h3><div class="value">$($ReportData.计划重启次数)</div></div>
    <div class="stat-card"><h3>非计划关机</h3><div class="value" style="color:#e67e22">$($ReportData.非计划关机次数)</div></div>
  </div>

  <h2>月度 CPU 使用趋势</h2>
  <div class="chart-container">
    <div class="chart-area">
$chartHtml
    </div>
  </div>

  <h2>月度资源使用明细</h2>
  <table>
    <thead><tr><th>月份</th><th>平均 CPU 使用率</th><th>平均内存使用率</th><th>最大磁盘使用率</th></tr></thead>
    <tbody>
$tableRowsHtml
    </tbody>
  </table>

  <div class="footer">本报告由 PowerShell 自动生成 | $($ReportData.生成时间)</div>
</body>
</html>
"@

    $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "HTML 报告已生成: $OutputPath" -ForegroundColor Green
    return (Resolve-Path $OutputPath).Path
}

# 生成 HTML 报告
$reportPath = New-YearEndHtmlReport -ReportData $reportData
```

执行结果示例：

```
HTML 报告已生成: /Users/user/reports/YearEnd-Report-2025.html
```

生成的 HTML 文件包含卡片式核心指标概览、纯 CSS 柱状图展示月度 CPU 趋势、以及带悬停效果的资源使用明细表格。整个报告无需任何 JavaScript 依赖，打开即可查看完整内容，也可通过浏览器"另存为 PDF"直接导出。

## 报告分发与归档

报告生成后，还需要将其自动发送给相关干系人并归档保存。下面的脚本实现了邮件分发、PDF 转换和按月份归档的完整流程。

```powershell
function Send-YearEndReport {
    <#
    .SYNOPSIS
    通过邮件发送年终报告并归档到指定目录
    .PARAMETER ReportPath
    HTML 报告文件路径
    .PARAMETER Recipients
    收件人邮箱地址数组
    .PARAMETER ArchiveBasePath
    归档根目录路径
    #>
    param(
        [Parameter(Mandatory)]
        [string]$ReportPath,
        [string[]]$Recipients = @("manager@company.com", "it-ops@company.com"),
        [string]$ArchiveBasePath = ".\Reports\Archive"
    )

    # ---- 1. 创建归档目录结构 ----
    $year = (Get-Date).Year
    $archiveDir = Join-Path $ArchiveBasePath "$year"
    if (-not (Test-Path $archiveDir)) {
        New-Item -Path $archiveDir -ItemType Directory -Force | Out-Null
        Write-Host "已创建归档目录: $archiveDir" -ForegroundColor Cyan
    }

    # 复制报告到归档目录（带时间戳）
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $archiveName = "YearEnd-Report-$year-$timestamp.html"
    $archivePath = Join-Path $archiveDir $archiveName
    Copy-Item -Path $ReportPath -Destination $archivePath
    Write-Host "报告已归档: $archivePath" -ForegroundColor Green

    # ---- 2. 生成 PDF 副本（利用 Chrome 无头模式） ----
    $pdfPath = $archivePath -replace '\.html$', '.pdf'
    $chromePaths = @(
        "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
    )
    $chrome = $chromePaths | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($chrome) {
        $pdfArgs = @(
            "--headless",
            "--disable-gpu",
            "--no-sandbox",
            "--print-to-pdf=$pdfPath",
            "--print-to-pdf-no-header",
            $archivePath
        )
        Start-Process -FilePath $chrome -ArgumentList $pdfArgs -Wait -NoNewWindow
        Write-Host "PDF 已生成: $pdfPath" -ForegroundColor Green
    } else {
        Write-Host "未找到 Chrome，跳过 PDF 生成。可手动在浏览器中另存为 PDF。" -ForegroundColor Yellow
        $pdfPath = $null
    }

    # ---- 3. 发送邮件 ----
    $mailParams = @{
        From       = "it-automation@company.com"
        To         = $Recipients
        Subject    = "[IT 运维] $year 年度报告"
        Body       = "各位好，`n`n附件为 $year 年度 IT 运维报告。`n`n报告由系统自动生成，如有疑问请联系 IT 运维团队。`n`n祝好"
        SmtpServer = "smtp.company.com"
        Port       = 587
        Encoding   = [System.Text.Encoding]::UTF8
    }

    # 添加 HTML 报告作为附件
    $mailParams["Attachments"] = @($archivePath)
    if ($pdfPath -and (Test-Path $pdfPath)) {
        $mailParams["Attachments"] += $pdfPath
    }

    try {
        Send-MailMessage @mailParams -ErrorAction Stop
        Write-Host "邮件已发送至: $($Recipients -join ', ')" -ForegroundColor Green
    } catch {
        Write-Host "邮件发送失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "请检查 SMTP 配置或网络连接" -ForegroundColor Yellow
    }

    # ---- 4. 生成归档索引 ----
    $indexEntry = [PSCustomObject]@{
        报告名称 = $archiveName
        生成时间 = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        文件大小KB = [math]::Round((Get-Item $archivePath).Length / 1KB, 1)
        归档路径 = $archivePath
        PDF路径 = $pdfPath
    }

    $indexPath = Join-Path $archiveDir "index.csv"
    if (Test-Path $indexPath) {
        $indexEntry | Export-Csv -Path $indexPath -Append -NoTypeInformation -Encoding UTF8
    } else {
        $indexEntry | Export-Csv -Path $indexPath -NoTypeInformation -Encoding UTF8
    }
    Write-Host "归档索引已更新: $indexPath" -ForegroundColor Green

    return $indexEntry
}

# 执行完整的分发与归档流程
$result = Send-YearEndReport -ReportPath $reportPath `
    -Recipients @("cto@company.com", "it-manager@company.com") `
    -ArchiveBasePath ".\Reports\Archive"

$result | Format-List
```

执行结果示例：

```
已创建归档目录: .\Reports\Archive\2025
报告已归档: .\Reports\Archive\2025\YearEnd-Report-2025-20251229-143022.html
PDF 已生成: .\Reports\Archive\2025\YearEnd-Report-2025-20251229-143022.pdf
邮件已发送至: cto@company.com, it-manager@company.com
归档索引已更新: .\Reports\Archive\2025\index.csv

报告名称 : YearEnd-Report-2025-20251229-143022.html
生成时间 : 2025-12-29 14:30:22
文件大小KB : 4.2
归档路径 : .\Reports\Archive\2025\YearEnd-Report-2025-20251229-143022.html
PDF路径   : .\Reports\Archive\2025\YearEnd-Report-2025-20251229-143022.pdf
```

## 注意事项

1. **事件日志权限**：读取 Windows 安全日志（Security Log）需要管理员权限。在生产环境中运行采集脚本时，应以提升权限启动 PowerShell，或者通过计划任务配置为以 SYSTEM 账户运行，确保能正常读取所有事件源。

2. **大数据量性能**：如果事件日志条目超过数十万条，直接使用 `Get-WinEvent` 可能占用大量内存。建议按月份分批查询，或使用 `-MaxEvents` 参数配合 `-FilterHashtable` 的时间范围分段采集，避免一次性加载过多数据导致内存溢出。

3. **CSV 数据格式约定**：资源指标 CSV 文件应包含 `Date`、`CPU`、`Memory`、`DiskUsage` 等标准列名。如果监控系统导出的字段名不同，需在采集函数中添加字段映射逻辑，或使用 `Select-Object` 的计算属性进行重命名。

4. **SMTP 认证配置**：示例中的 `Send-MailMessage` 使用了简化的参数。在生产环境中，SMTP 服务器通常需要身份认证和 TLS 加密。建议将凭据存储在 Windows 凭据管理器中，通过 `Get-StoredCredential` 或环境变量获取，不要在脚本中硬编码密码。

5. **Chrome 无头模式依赖**：PDF 转换功能依赖 Chrome 或 Chromium 浏览器。在无 GUI 的 Windows Server 上，需要安装 Chrome 并确保无头模式可以正常运行。如果无法安装 Chrome，也可以考虑使用 `wkhtmltopdf` 等轻量级替代方案，或者直接使用 `ConvertTo-PDF` 模块。

6. **报告模板维护**：HTML 报告模板中的样式和结构应与企业管理规范保持一致。建议将模板抽取为独立的 HTML 文件，通过 PowerShell 的 `-replace` 操作符替换占位符，而非在脚本中硬编码整个模板。这样设计人员可以独立调整样式，开发人员只需关注数据填充逻辑。
