---
layout: post
date: 2025-09-18 08:00:00
updated: 2025-09-18 08:00:00
title: "PowerShell 技能连载 - Excel 报表自动化"
description: PowerTip of the Day - Excel Report Automation in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- office
- reporting
---

_适用于 PowerShell 5.1 及以上版本（Windows）_

在企业运维和数据分析场景中，定期生成 Excel 报表是一项高频需求。传统的做法是手动导出 CSV 再用 Excel 打开，或者借助 COM 对象操作 Excel 应用程序——前者丢失格式信息，后者需要安装 Office 且速度慢、容易卡死。有没有一种方式既能生成带格式的原生 `.xlsx` 文件，又不需要安装 Excel 呢？

答案是使用 **EPPlus** 库。EPPlus 是一个成熟的 .NET 开源组件，可以直接在内存中创建、读写 Excel 文件，支持单元格样式、公式、图表、数据验证等高级功能。通过 PowerShell 加载 EPPlus 的 DLL 文件，我们就能以纯脚本的方式完成复杂的报表生成任务，非常适合无人值守的自动化场景。

本文将从安装 EPPlus 开始，逐步演示如何用 PowerShell 生成一份包含表头样式、数据填充、条件格式和自动筛选的专业级 Excel 报表。

<!-- more -->

## 安装 EPPlus 库

EPPlus 从 5.0 版本开始采用 Polyform Noncommercial 许可证，对于个人学习和内部运维使用完全免费。我们可以通过 NuGet 包管理器下载 DLL，也可以直接从 GitHub Release 页面获取。下面演示一种最简单的安装方式：利用 `Install-Package` 命令将 EPPlus 安装到本地目录。

```powershell
# 创建专用目录存放 NuGet 包
$packageDir = "$env:USERPROFILE\Documents\PowerShell\Modules\EPPlus"
if (-not (Test-Path $packageDir)) {
    New-Item -Path $packageDir -ItemType Directory -Force | Out-Null
}

# 安装 EPPlus NuGet 包
Save-Package -Name EPPlus -Path $packageDir -Source "https://www.nuget.org/api/v2"
Get-ChildItem -Path $packageDir -Recurse -Filter "EPPlus.dll" |
    Select-Object FullName, Length
```

```text
FullName                                                    Size
--------                                                    ----
C:\Users\admin\Documents\PowerShell\Modules\EPPlus\...      2457600
```

安装完成后，记下 `EPPlus.dll` 的完整路径，后续脚本中需要用它来加载程序集。

## 创建基础报表

这一步演示如何加载 EPPlus 库、创建工作簿、写入表头和数据行，并应用基本的单元格样式。我们会用模拟的服务器资产数据作为示例。

```powershell
# 加载 EPPlus 程序集
Add-Type -Path "$env:USERPROFILE\Documents\PowerShell\Modules\EPPlus\EPPlus.dll"

# 创建 Excel 包和工作表
$package = [OfficeOpenXml.ExcelPackage]::new()
$worksheet = $package.Workbook.Worksheets.Add("服务器资产")

# 定义表头
$headers = @("序号", "服务器名称", "IP 地址", "CPU 利用率(%)", "内存利用率(%)", "磁盘剩余(GB)", "状态")
foreach ($i in 0..($headers.Count - 1)) {
    $cell = $worksheet.Cells[1, $i + 1]
    $cell.Value = $headers[$i]
    $cell.Style.Font.Bold = $true
    $cell.Style.Font.Size = 11
    $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
    $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::SteelBlue)
    $cell.Style.Font.Color.SetColor([System.Drawing.Color]::White)
    $cell.Style.HorizontalAlignment = [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Center
}

# 填充模拟数据
$servers = @(
    @{ Name = "WEB-01"; IP = "10.0.1.10"; CPU = 72; Mem = 85; Disk = 120; Status = "警告" }
    @{ Name = "WEB-02"; IP = "10.0.1.11"; CPU = 45; Mem = 60; Disk = 340; Status = "正常" }
    @{ Name = "DB-01";  IP = "10.0.2.20"; CPU = 88; Mem = 92; Disk = 50;  Status = "告警" }
    @{ Name = "DB-02";  IP = "10.0.2.21"; CPU = 35; Mem = 48; Disk = 280; Status = "正常" }
    @{ Name = "APP-01"; IP = "10.0.3.30"; CPU = 61; Mem = 73; Disk = 195; Status = "正常" }
)

$row = 2
foreach ($srv in $servers) {
    $worksheet.Cells[$row, 1].Value = $row - 1
    $worksheet.Cells[$row, 2].Value = $srv.Name
    $worksheet.Cells[$row, 3].Value = $srv.IP
    $worksheet.Cells[$row, 4].Value = $srv.CPU
    $worksheet.Cells[$row, 5].Value = $srv.Mem
    $worksheet.Cells[$row, 6].Value = $srv.Disk
    $worksheet.Cells[$row, 7].Value = $srv.Status
    $row++
}

# 自动适配列宽
$worksheet.Cells[$worksheet.Dimension.Address].AutoFitColumns()

# 保存文件
$outputPath = "$env:USERPROFILE\Desktop\ServerReport.xlsx"
$package.SaveAs([System.IO.FileInfo]::new($outputPath))
$package.Dispose()
Write-Host "报表已保存至: $outputPath"
```

```text
报表已保存至: C:\Users\admin\Desktop\ServerReport.xlsx
```

这段代码生成了一个包含蓝色表头、白色粗体文字的 Excel 文件，数据区域自动适配列宽，打开即可看到整洁的表格。

## 添加条件格式与汇总行

仅有原始数据的报表还不够直观。下面我们在已有基础上增加条件格式——当 CPU 利用率超过 80% 时单元格标红，并在表格末尾添加汇总统计行。同时为整个数据区域开启自动筛选，方便用户按列筛选数据。

```powershell
Add-Type -Path "$env:USERPROFILE\Documents\PowerShell\Modules\EPPlus\EPPlus.dll"

$package = [OfficeOpenXml.ExcelPackage]::new($outputPath)
$ws = $package.Workbook.Worksheets["服务器资产"]

# 获取数据范围
$dataRange = $ws.Dimension
$rowCount = $dataRange.End.Row

# 为 CPU 利用率列添加条件格式（红色背景）
$cpuRange = "D2:D$rowCount"
$condFmt = $ws.ConditionalFormatting.AddGreaterThan($cpuRange)
$condFmt.Formula = "80"
$condFmt.Style.Fill.BackgroundColor.Color = [System.Drawing.Color]::LightPink
$condFmt.Style.Font.Color.Color = [System.Drawing.Color]::DarkRed

# 为内存利用率列添加条件格式（橙色背景）
$memRange = "E2:E$rowCount"
$condFmt2 = $ws.ConditionalFormatting.AddGreaterThan($memRange)
$condFmt2.Formula = "80"
$condFmt2.Style.Fill.BackgroundColor.Color = [System.Drawing.Color]::Moccasin
$condFmt2.Style.Font.Color.Color = [System.Drawing.Color]::DarkOrange

# 为状态列添加条件格式——"告警"标红，"警告"标黄
$statusRange = "G2:G$rowCount"
$condRed = $ws.ConditionalFormatting.AddEqual($statusRange)
$condRed.Formula = '"告警"'
$condRed.Style.Fill.BackgroundColor.Color = [System.Drawing.Color]::Tomato
$condRed.Style.Font.Color.Color = [System.Drawing.Color]::White

$condYellow = $ws.ConditionalFormatting.AddEqual($statusRange)
$condYellow.Formula = '"警告"'
$condYellow.Style.Fill.BackgroundColor.Color = [System.Drawing.Color]::Gold

# 添加汇总行
$summaryRow = $rowCount + 1
$ws.Cells[$summaryRow, 1].Value = "汇总"
$ws.Cells[$summaryRow, 1].Style.Font.Bold = $true

$ws.Cells[$summaryRow, 4].Value = "平均"
$ws.Cells[$summaryRow, 4].Style.Font.Bold = $true
$ws.Cells[$summaryRow, 5].Formula = "AVERAGE(E2:E$rowCount)"
$ws.Cells[$summaryRow, 5].Style.Numberformat.Format = "0.0"
$ws.Cells[$summaryRow, 5].Style.Font.Bold = $true

$ws.Cells[$summaryRow, 6].Value = "总计"
$ws.Cells[$summaryRow, 6].Style.Font.Bold = $true
$ws.Cells[$summaryRow, 6].Formula = "SUM(F2:F$rowCount)"
$ws.Cells[$summaryRow, 6].Style.Numberformat.Format = "#,##0"

# 为汇总行添加灰色背景
foreach ($col in 1..7) {
    $ws.Cells[$summaryRow, $col].Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
    $ws.Cells[$summaryRow, $col].Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::LightGray)
}

# 启用自动筛选
$ws.Cells[$dataRange.Address].AutoFilter = $true

# 冻结首行（固定表头）
$ws.View.FreezePanes(2, 1)

# 保存并关闭
$package.Save()
$package.Dispose()
Write-Host "报表已更新，添加了条件格式、汇总行和自动筛选"
```

```text
报表已更新，添加了条件格式、汇总行和自动筛选
```

打开更新后的报表，你会发现 CPU 利用率超过 80% 的单元格自动标红，状态为"告警"的行也有醒目的红色背景。滚动时表头固定不动，第一行筛选箭头可以按任意列过滤数据。

## 从 CSV 数据批量生成多工作表报表

在实际运维中，数据通常来自多个 CSV 文件。下面演示一个更贴近实战的场景：读取目录下的 CSV 文件，为每个文件创建独立的工作表，并统一应用报表样式。

```powershell
Add-Type -Path "$env:USERPROFILE\Documents\PowerShell\Modules\EPPlus\EPPlus.dll"

# 模拟生成 CSV 数据文件
$csvDir = "$env:USERPROFILE\Desktop\CsvData"
if (-not (Test-Path $csvDir)) {
    New-Item -Path $csvDir -ItemType Directory -Force | Out-Null
}

# 模拟网络流量数据
$networkData = @(
    [PSCustomObject]@{ 时间 = "08:00"; 接收MB = 120; 发送MB = 85; 连接数 = 342 }
    [PSCustomObject]@{ 时间 = "09:00"; 接收MB = 350; 发送MB = 210; 连接数 = 580 }
    [PSCustomObject]@{ 时间 = "10:00"; 接收MB = 480; 发送MB = 320; 连接数 = 712 }
    [PSCustomObject]@{ 时间 = "11:00"; 接收MB = 390; 发送MB = 275; 连接数 = 650 }
    [PSCustomObject]@{ 时间 = "12:00"; 接收MB = 210; 发送MB = 145; 连接数 = 410 }
)
$networkData | Export-Csv -Path "$csvDir\network.csv" -NoTypeInformation -Encoding UTF8

# 模拟安全审计数据
$securityData = @(
    [PSCustomObject]@{ 事件 = "登录失败"; 次数 = 23; 来源IP = "192.168.1.105"; 严重级别 = "中" }
    [PSCustomObject]@{ 事件 = "端口扫描"; 次数 = 5;  来源IP = "10.0.5.88";    严重级别 = "高" }
    [PSCustomObject]@{ 事件 = "异常下载"; 次数 = 12; 来源IP = "10.0.3.42";    严重级别 = "高" }
    [PSCustomObject]@{ 事件 = "密码修改"; 次数 = 8;  来源IP = "10.0.2.15";    严重级别 = "低" }
)
$securityData | Export-Csv -Path "$csvDir\security.csv" -NoTypeInformation -Encoding UTF8

# 创建 Excel 包
$pkg = [OfficeOpenXml.ExcelPackage]::new()
$csvFiles = Get-ChildItem -Path $csvDir -Filter "*.csv"

foreach ($csvFile in $csvFiles) {
    # 读取 CSV 数据
    $data = Import-Csv -Path $csvFile.FullName -Encoding UTF8
    if ($data.Count -eq 0) {
        continue
    }

    # 以文件名作为工作表名（去除特殊字符）
    $sheetName = [System.IO.Path]::GetFileNameWithoutExtension($csvFile.Name)
    $sheet = $pkg.Workbook.Worksheets.Add($sheetName)

    # 获取属性名作为表头
    $properties = $data[0].PSObject.Properties.Name

    # 写入表头
    foreach ($col in 0..($properties.Count - 1)) {
        $cell = $sheet.Cells[1, $col + 1]
        $cell.Value = $properties[$col]
        $cell.Style.Font.Bold = $true
        $cell.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
        $cell.Style.Fill.BackgroundColor.SetColor([System.Drawing.Color]::DarkSlateBlue)
        $cell.Style.Font.Color.SetColor([System.Drawing.Color]::White)
        $cell.Style.HorizontalAlignment = [OfficeOpenXml.Style.ExcelHorizontalAlignment]::Center
    }

    # 写入数据行
    $row = 2
    foreach ($item in $data) {
        foreach ($col in 0..($properties.Count - 1)) {
            $sheet.Cells[$row, $col + 1].Value = $item.($properties[$col])
        }
        $row++
    }

    # 自动适配列宽并添加筛选
    $sheet.Cells[$sheet.Dimension.Address].AutoFitColumns()
    $sheet.Cells[$sheet.Dimension.Address].AutoFilter = $true
    $sheet.View.FreezePanes(2, 1)

    Write-Host "已添加工作表: $sheetName ($($data.Count) 行数据)"
}

# 保存最终报表
$finalPath = "$env:USERPROFILE\Desktop\MultiSheetReport.xlsx"
$pkg.SaveAs([System.IO.FileInfo]::new($finalPath))
$pkg.Dispose()
Write-Host "`n多工作表报表已保存至: $finalPath"
```

```text
已添加工作表: network (5 行数据)
已添加工作表: security (4 行数据)

多工作表报表已保存至: C:\Users\admin\Desktop\MultiSheetReport.xlsx
```

这个脚本展示了从 CSV 到 Excel 的完整转换流程。每个 CSV 文件对应一个独立的工作表，表头自动从 CSV 列名提取，样式统一应用。你可以轻松扩展这个脚本，加入更多数据源或定时任务调度。

## 注意事项

- **许可证合规**：EPPlus 5.x 采用 Polyform Noncommercial 许可证，商业项目需购买商业许可证。如果仅用于内部运维和个人学习，免费版本完全满足需求。若项目有商业用途，可考虑使用 EPPlus 4.x（LGPL 许可）或替代库如 ClosedXML。
- **性能考量**：EPPlus 在内存中操作，生成万行级别的报表通常只需几秒。但对于十万行以上的大型数据集，建议分批写入并使用 `LoadFromCollection` 方法代替逐单元格赋值，可显著提升性能。
- **路径处理**：EPPlus 的 `SaveAs` 方法接受 `System.IO.FileInfo` 对象或完整路径字符串。当路径中包含中文或空格时，务必使用 `FileInfo` 对象并确保目录已存在，避免因路径编码问题导致保存失败。
- **DLL 加载冲突**：如果系统中已存在其他版本的 EPPlus（例如通过其他工具安装），可能会遇到程序集版本冲突。建议在脚本开头使用 `Remove-Module` 清理已有加载，或为不同版本使用独立的 DLL 副本。
- **中文编码**：导出的 CSV 文件如果包含中文，务必在 `Export-Csv` 时指定 `-Encoding UTF8` 参数，否则 EPPlus 读取后可能出现乱码。Windows PowerShell 5.1 默认编码为 ASCII，PowerShell 7 默认为 UTF-8，两者行为不同。
- **资源释放**：每次操作完成后务必调用 `$package.Dispose()` 释放资源。EPPlus 内部使用 `System.IO.Packaging` 操作 ZIP 包（xlsx 本质是 ZIP 压缩文件），未释放可能导致文件句柄泄露，后续操作报"文件被占用"错误。
