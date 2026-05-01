---
layout: post
date: 2026-01-21 08:00:00
title: "PowerShell 技能连载 - Excel 自动化报表"
description: PowerTip of the Day - Excel Automation Reports in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- excel
- importexcel
- reporting
- data-analysis
---

_适用于 PowerShell 5.1 及以上版本_

在企业环境中，Excel 是最通用的数据交换格式之一。无论是系统运维的周报、安全审计的统计报告，还是业务分析的汇总数据，Excel 报表几乎无处不在。然而，手动从多个数据源收集信息、格式化表格、生成图表并分发报表，这个过程既耗时又容易出错。

ImportExcel 模块的出现彻底改变了这一局面。它是一个纯 PowerShell 实现的 .xlsx 文件操作库，无需安装 Microsoft Excel 即可完成读取、写入、图表生成、条件格式等操作。这意味着你可以在 Windows Server Core 甚至 Linux 服务器上运行报表生成脚本，完全不依赖 Office 组件。

本文将通过三个递进的场景，带你掌握从基础数据导入导出到自动化报表分发的完整工作流。无论你是需要将系统日志转换为可读报表，还是要定期向管理层发送格式化的运维报告，这些技巧都能帮你节省大量时间。

## 数据导入导出

ImportExcel 最基础的能力是读取和写入 Excel 文件。下面的示例展示了如何读取一个包含服务器资产清单的 Excel 文件，按状态筛选数据，并将结果导出为新的报表文件。

```powershell
# 安装 ImportExcel 模块（仅需执行一次）
Install-Module -Name ImportExcel -Scope CurrentUser -Force

# 读取服务器资产清单
$assetFile = "C:\Reports\ServerAssets.xlsx"
$allServers = Import-Excel -Path $assetFile -WorksheetName "资产清单"

Write-Host "共读取 $($allServers.Count) 条服务器记录"

# 筛选在线服务器并按内存使用率排序
$onlineServers = $allServers |
    Where-Object { $_.状态 -eq '在线' } |
    Sort-Object -Property { [double]$_.内存使用率 } -Descending

# 计算汇总统计
$summary = [PSCustomObject]@{
    总数     = $allServers.Count
    在线数   = ($allServers | Where-Object { $_.状态 -eq '在线' }).Count
    离线数   = ($allServers | Where-Object { $_.状态 -eq '离线' }).Count
    平均内存 = '{0:N1}%' -f (($onlineServers | ForEach-Object { [double]$_.内存使用率 } | Measure-Object -Average).Average)
}

# 导出筛选结果和汇总到新 Excel 文件
$outputPath = "C:\Reports\OnlineServers_$(Get-Date -Format 'yyyyMMdd').xlsx"

# 使用自动表格样式导出
$onlineServers | Select-Object 主机名, IP地址, 操作系统, CPU核数, 内存使用率, 磁盘剩余, 最后响应时间 |
    Export-Excel -Path $outputPath -WorksheetName "在线服务器" -TableName "ServerTable" -TableStyle Light1 -AutoSize

$summary | Export-Excel -Path $outputPath -WorksheetName "汇总" -StartRow 1

Write-Host "报表已导出到: $outputPath"
```

```text
共读取 156 条服务器记录
报表已导出到: C:\Reports\OnlineServers_20260121.xlsx
```

导出的 Excel 文件包含两个工作表：「在线服务器」以表格形式展示筛选后的服务器详情，「汇总」提供一目了然的统计数字。`-AutoSize` 参数自动调整列宽，`-TableStyle` 参数应用内置表格样式，让报表专业且易读。

## 图表与格式化

纯数字的报表缺少直观性。ImportExcel 支持通过 `Add-ExcelChart` 命令在 Excel 中创建柱状图、饼图、折线图等多种图表，还能使用 `Set-ExcelRange` 添加条件格式，让关键数据一目了然。

```powershell
# 准备示例数据：各区域服务器状态统计
$regionData = @(
    [PSCustomObject]@{ 区域 = '华东'; 在线 = 45; 离线 = 3; 维护中 = 2 }
    [PSCustomObject]@{ 区域 = '华北'; 在线 = 38; 离线 = 5; 维护中 = 1 }
    [PSCustomObject]@{ 区域 = '华南'; 在线 = 32; 离线 = 2; 维护中 = 3 }
    [PSCustomObject]@{ 区域 = '西南'; 在线 = 15; 离线 = 1; 维护中 = 1 }
    [PSCustomObject]@{ 区域 = '东北'; 在线 = 8;  离线 = 0; 维护中 = 0 }
)

$chartFile = "C:\Reports\RegionStatus_$(Get-Date -Format 'yyyyMMdd').xlsx"

# 导出数据并附加柱状图
$excel = $regionData | Export-Excel -Path $chartFile -WorksheetName "区域统计" -TableName "RegionTable" -PassThru

$sheet = $excel.Workbook.Worksheets["区域统计"]

# 添加簇状柱状图
Add-ExcelChart -Worksheet $sheet -ChartType ColumnClustered `
    -XRange "A2:A6" `
    -YRange "B2:D6" `
    -Title "各区域服务器状态分布" `
    -SeriesHeader "在线", "离线", "维护中" `
    -Width 800 -Height 400 `
    -Row 8 -Column 1

# 为在线列添加数据条条件格式
Set-ExcelRange -Worksheet $sheet -Range "B2:B6" -ConditionalFormat {
    param($cond)
    $cond.SetDataBar(
        [OfficeOpenXml.ConditionalFormatting.ExcelBarColor]::Green
    )
}

# 为离线列添加高亮条件格式（值大于 3 时显示红色）
Set-ExcelRange -Worksheet $sheet -Range "C2:C6" -ConditionalFormat {
    param($cond)
    $rule = $cond.AddGreaterThanOrEqual()
    $rule.Formula = "3"
    $rule.Style.Fill.BackgroundColor.Color = [System.Drawing.Color]::LightPink
}

# 设置标题行样式
Set-ExcelRange -Worksheet $sheet -Range "A1:G1" -Bold -FontSize 12 -BackgroundColor ([System.Drawing.Color]::SteelBlue) -FontColor ([System.Drawing.Color]::White)

Close-ExcelPackage -ExcelPackage $excel -Save

Write-Host "图表报表已生成: $chartFile"
```

```text
图表报表已生成: C:\Reports\RegionStatus_20260121.xlsx
```

这段代码生成了一个包含簇状柱状图的 Excel 报表。在线服务器数量列带有绿色数据条，直观反映各区域的容量规模；离线数量超过阈值的单元格自动标红，方便运维人员快速定位问题区域。`-PassThru` 参数返回 Excel 包对象，允许我们在保存前进行更多自定义操作。

## 自动化报表生成

将前面的技术整合起来，就可以构建一个完整的自动化报表工作流：从多个数据源汇总信息，生成多 Sheet 报表，并通过邮件自动分发。

```powershell
function New-WeeklyOpsReport {
    <#
    .SYNOPSIS
    生成运维周报并自动发送邮件
    #>
    param(
        [string]$OutputPath = "C:\Reports\WeeklyOps_$(Get-Date -Format 'yyyyMMdd').xlsx",
        [string[]]$Recipients = @("ops-team@company.com", "manager@company.com")
    )

    $reportDate = Get-Date -Format "yyyy年MM月dd日"

    # --- 数据采集 ---
    # 模拟从各系统采集的数据（实际环境中可替换为 API 调用、数据库查询等）
    $eventStats = @(
        [PSCustomObject]@{ 类型 = '错误'; 本周 = 23; 上周 = 31; 趋势 = '下降' }
        [PSCustomObject]@{ 类型 = '警告'; 本周 = 156; 上周 = 142; 趋势 = '上升' }
        [PSCustomObject]@{ 类型 = '信息'; 本周 = 8432; 上周 = 7891; 趋势 = '上升' }
    )

    $patchCompliance = @(
        [PSCustomObject]@{ 分类 = '安全补丁'; 合格率 = '94.2%'; 待处理 = 12 }
        [PSCustomObject]@{ 分类 = '功能更新'; 合格率 = '87.5%'; 待处理 = 28 }
        [PSCustomObject]@{ 分类 = '驱动程序'; 合格率 = '96.1%'; 待处理 = 5 }
    )

    # --- 生成 Excel 报表 ---
    $excel = Export-Excel -Path $OutputPath -PassThru

    # Sheet 1：概览摘要
    $overview = [PSCustomObject]@{
        报告日期    = $reportDate
        报告周期    = "$(Get-Date (Get-Date).AddDays(-7) -Format 'MM/dd') - $(Get-Date -Format 'MM/dd')"
        服务器总数  = 156
        在线率      = '97.4%'
        平均响应时间 = '23ms'
    }
    $overview | Export-Excel -ExcelPackage $excel -WorksheetName "概览" -AutoSize -BoldTopRow

    # Sheet 2：事件统计（含图表）
    $eventSheet = $eventStats | Export-Excel -ExcelPackage $excel -WorksheetName "事件统计" -TableName "EventTable" -PassThru
    Add-ExcelChart -Worksheet $eventSheet.Workbook.Worksheets["事件统计"] `
        -ChartType BarClustered `
        -XRange "A2:A4" -YRange "B2:C4" `
        -Title "事件趋势对比（本周 vs 上周）" `
        -SeriesHeader "本周", "上周" `
        -Row 6 -Column 1 -Width 700 -Height 350

    # Sheet 3：补丁合规率
    $patchCompliance | Export-Excel -ExcelPackage $excel -WorksheetName "补丁合规" -TableName "PatchTable" -AutoSize -NumberFormat '0.0%'

    # 保存并关闭
    Close-ExcelPackage -ExcelPackage $excel -Save

    Write-Host "报表已生成: $OutputPath"

    # --- 发送邮件 ---
    $smtpServer = "smtp.company.com"
    $from = "ops-report@company.com"
    $subject = "[自动化] 运维周报 - $reportDate"

    $body = @"
各位好，

本周运维报表已自动生成，请查阅附件。

主要指标：
- 服务器在线率：97.4%
- 安全补丁合规率：94.2%
- 错误事件：23 起（较上周下降 25.8%）

此邮件由自动化系统发送，请勿直接回复。
"@

    Send-MailMessage -From $from -To $Recipients -Subject $subject -Body $body -SmtpServer $smtpServer -Attachments $OutputPath -Encoding UTF8

    Write-Host "报表已发送至: $($Recipients -join ', ')"
}

# 执行周报生成
New-WeeklyOpsReport
```

```text
报表已生成: C:\Reports\WeeklyOps_20260121.xlsx
报表已发送至: ops-team@company.com, manager@company.com
```

这个函数实现了一个完整的自动化报表管道。它将数据采集、报表生成和邮件分发整合到一个可复用的函数中。三个 Sheet 分别承载概览摘要、事件趋势图表和补丁合规明细，满足不同受众的需求。结合 Windows 任务计划程序或 Linux 的 cron，就可以实现真正的无人值守周报。

## 注意事项

- ImportExcel 模块依赖 .NET 的 EPPlus 库，无需安装 Microsoft Excel，可以在 Server Core 和 Linux 环境中运行，但需要确保 PowerShell 版本满足 5.1 及以上。
- 使用 `Export-Excel` 的 `-PassThru` 参数时，务必在操作完成后调用 `Close-ExcelPackage -Save` 保存文件，否则修改不会写入磁盘，且可能造成文件句柄泄漏。
- `Add-ExcelChart` 的 `-XRange` 和 `-YRange` 参数引用的是 Excel 单元格范围，如果数据行数动态变化，需要先计算范围字符串再传入，避免图表数据截断。
- 条件格式的设置使用 EPPlus 的原生 API，语法与 VBA 中的条件格式对象模型有差异，编写时建议参考 EPPlus 官方文档。
- 邮件发送部分使用 `Send-MailMessage`，该 cmdlet 在 PowerShell 7.x 中标记为已过时，生产环境建议使用 `MailKit` 库或调用 REST API（如 Microsoft Graph）来发送邮件。
- 处理大型 Excel 文件（超过 10 万行）时，建议使用 `-NoNumberFormat` 和 `-AsText` 参数关闭自动类型推断，可以显著提升导入导出的性能。
