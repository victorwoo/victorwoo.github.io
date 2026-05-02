---
layout: post
date: 2025-07-18 08:00:00
updated: 2025-07-18 08:00:00
title: "PowerShell 技能连载 - CSV 高级处理"
description: PowerTip of the Day - Advanced CSV Processing in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- csv
- data-processing
- import-export
---

_适用于 PowerShell 5.1 及以上版本_

CSV（逗号分隔值）是运维中最常见的数据交换格式——导出用户清单、导入配置数据、处理监控报表、批量操作清单。虽然 PowerShell 的 `Import-Csv` 和 `Export-Csv` 命令简单易用，但面对大数据量、复杂转换、编码问题、多文件合并等场景时，需要掌握更多技巧。

本文将讲解 CSV 处理的高级技巧和实用场景。

## CSV 读写基础

```powershell
# 创建测试数据
$employees = @(
    [PSCustomObject]@{ Name = "张三"; Department = "工程部"; Salary = 25000; JoinDate = "2023-03-15" }
    [PSCustomObject]@{ Name = "李四"; Department = "市场部"; Salary = 20000; JoinDate = "2023-06-01" }
    [PSCustomObject]@{ Name = "王五"; Department = "工程部"; Salary = 30000; JoinDate = "2022-01-10" }
    [PSCustomObject]@{ Name = "赵六"; Department = "人事部"; Salary = 22000; JoinDate = "2024-02-20" }
    [PSCustomObject]@{ Name = "孙七"; Department = "工程部"; Salary = 28000; JoinDate = "2023-09-05" }
)

$employees | Export-Csv -Path "C:\Data\employees.csv" -NoTypeInformation -Encoding UTF8
Write-Host "已导出 CSV" -ForegroundColor Green

# 读取 CSV
$data = Import-Csv -Path "C:\Data\employees.csv" -Encoding UTF8
Write-Host "读取 $($data.Count) 条记录" -ForegroundColor Cyan

# CSV 数据天然就是对象集合，可以直接操作
$data | Where-Object { $_.Department -eq "工程部" } |
    Sort-Object Salary -Descending |
    Format-Table Name, Salary -AutoSize

# 使用 -Delimiter 处理非逗号分隔符
# Import-Csv -Path "data.tsv" -Delimiter "`t"

# 指定列名（文件没有标题行时）
# Import-Csv -Path "data.csv" -Header "Name","Dept","Salary" | Select-Object -Skip 1
```

执行结果示例：

```
已导出 CSV
读取 5 条记录
Name Salary
---- ------
王五 30000
孙七 28000
张三 25000
```

## 数据转换与计算

```powershell
# 读取并转换数据
$data = Import-Csv "C:\Data\employees.csv"

# 添加计算列
$enhanced = $data | Select-Object *, @{
    N = 'SalaryK'
    E = { [math]::Round([int]$_.Salary / 1000, 1) }
}, @{
    N = 'YearsOfService'
    E = { [math]::Round(((Get-Date) - [datetime]$_.JoinDate).TotalDays / 365, 1) }
}, @{
    N = 'AnnualSalary'
    E = { [int]$_.Salary * 12 }
}

$enhanced | Format-Table Name, Department, SalaryK, YearsOfService, AnnualSalary -AutoSize

# 分组统计
$deptStats = $data | Group-Object Department | ForEach-Object {
    $avgSalary = [math]::Round(($_.Group | ForEach-Object { [int]$_.Salary } | Measure-Object -Average).Average)
    $maxSalary = ($_.Group | ForEach-Object { [int]$_.Salary } | Measure-Object -Maximum).Maximum

    [PSCustomObject]@{
        Department = $_.Name
        Count      = $_.Count
        AvgSalary  = $avgSalary
        MaxSalary  = $maxSalary
    }
}

Write-Host "`n部门统计：" -ForegroundColor Cyan
$deptStats | Format-Table -AutoSize

# 数据透视
$pivot = $data | Group-Object Department | ForEach-Object {
    $names = ($_.Group | Select-Object -ExpandProperty Name) -join ', '
    [PSCustomObject]@{
        Department = $_.Name
        Count      = $_.Count
        Members    = $names
    }
}
$pivot | Format-Table -AutoSize
```

执行结果示例：

```
Name Department SalaryK YearsOfService AnnualSalary
---- ---------- ------- -------------- ------------
张三 工程部       25.0            2.3        300000
李四 市场部       20.0            2.1        240000
王五 工程部       30.0            3.5        360000
赵六 人事部       22.0            1.4        264000
孙七 工程部       28.0            1.9        336000

部门统计：
Department Count AvgSalary MaxSalary
---------- ----- ---------- ---------
工程部         3     27666     30000
市场部         1     20000     20000
人事部         1     22000     22000

Department Count Members
---------- ----- -------
工程部         3 张三, 王五, 孙七
市场部         1 李四
人事部         1 赵六
```

## 大文件高效处理

```powershell
# 流式处理大 CSV（不一次性加载到内存）
function Process-LargeCsv {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [scriptblock]$ProcessBlock,

        [int]$ReportInterval = 10000
    )

    $reader = [System.IO.StreamReader]::new($Path, [System.Text.Encoding]::UTF8)
    $header = $reader.ReadLine()

    if (-not $header) {
        $reader.Close()
        return
    }

    $columns = $header -split ','
    $count = 0
    $output = @()

    while ($null -ne ($line = $reader.ReadLine())) {
        $count++
        $values = $line -split ','
        $obj = [ordered]@{}
        for ($i = 0; $i -lt $columns.Count; $i++) {
            $obj[$columns[$i].Trim('"')] = if ($i -lt $values.Count) { $values[$i].Trim('"') } else { "" }
        }

        $result = & $ProcessBlock ([PSCustomObject]$obj)
        if ($result) { $output += $result }

        if ($count % $ReportInterval -eq 0) {
            Write-Host "  已处理 $count 行..." -ForegroundColor DarkGray
        }
    }

    $reader.Close()
    Write-Host "处理完成：$count 行" -ForegroundColor Green
    return $output
}

# 使用流式处理筛选数据
$filtered = Process-LargeCsv -Path "C:\Data\large-dataset.csv" -ProcessBlock {
    param($row)
    if ([int]$row.Amount -gt 10000) {
        $row
    }
} -ReportInterval 50000

Write-Host "筛选结果：$($filtered.Count) 条"

# 使用 StreamWriter 高效输出 CSV
function Export-CsvFast {
    param(
        [Parameter(Mandatory)]
        [object[]]$Data,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $writer = [System.IO.StreamWriter]::new($Path, $false, [System.Text.Encoding]::UTF8)

    try {
        if ($Data.Count -gt 0) {
            $properties = $Data[0].PSObject.Properties.Name
            $writer.WriteLine(($properties | ForEach-Object { "`"$_`"" }) -join ',')

            foreach ($item in $Data) {
                $values = foreach ($prop in $properties) {
                    $val = $item.$prop
                    if ($null -eq $val) { '""' }
                    elseif ($val -match '[,""\r\n]') { "`"$($val -replace '"', '""')`"" }
                    else { "`"$val`"" }
                }
                $writer.WriteLine(($values -join ','))
            }
        }
    } finally {
        $writer.Close()
    }
}
```

执行结果示例：

```
  已处理 10000 行...
  已处理 20000 行...
  已处理 30000 行...
处理完成：32500 行
筛选结果：1250 条
```

## 多文件合并与对比

```powershell
# 合并多个 CSV 文件
function Merge-CsvFiles {
    param(
        [Parameter(Mandatory)]
        [string[]]$Paths,

        [string]$OutputPath
    )

    $allData = @()
    foreach ($path in $Paths) {
        if (Test-Path $path) {
            $data = Import-Csv $path -Encoding UTF8
            $source = [System.IO.Path]::GetFileName($path)
            $data | ForEach-Object {
                $_ | Add-Member -NotePropertyName "Source" -NotePropertyValue $source -Force
            }
            $allData += $data
            Write-Host "已加载：$source ($($data.Count) 行)" -ForegroundColor Green
        }
    }

    $allData | Export-Csv $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "合并完成：$($allData.Count) 行 => $OutputPath" -ForegroundColor Cyan
}

# 按日期范围合并
$dateFiles = 1..5 | ForEach-Object {
    "C:\Data\report-$(Get-Date).AddDays(-$_).ToString('yyyyMMdd').csv"
}
Merge-CsvFiles -Paths $dateFiles -OutputPath "C:\Data\report-weekly.csv"

# CSV 对比
function Compare-CsvData {
    param(
        [Parameter(Mandatory)][string]$ReferenceFile,
        [Parameter(Mandatory)][string]$DifferenceFile,
        [Parameter(Mandatory)][string]$KeyColumn
    )

    $ref = Import-Csv $ReferenceFile -Encoding UTF8
    $diff = Import-Csv $DifferenceFile -Encoding UTF8

    $refKeys = $ref | Select-Object -ExpandProperty $KeyColumn
    $diffKeys = $diff | Select-Object -ExpandProperty $KeyColumn

    $added = $diffKeys | Where-Object { $_ -notin $refKeys }
    $removed = $refKeys | Where-Object { $_ -notin $diffKeys }
    $common = $refKeys | Where-Object { $_ -in $diffKeys }

    Write-Host "CSV 对比结果：" -ForegroundColor Cyan
    Write-Host "  新增：$($added.Count) 条" -ForegroundColor Green
    Write-Host "  删除：$($removed.Count) 条" -ForegroundColor Red
    Write-Host "  共有：$($common.Count) 条" -ForegroundColor Gray

    if ($added) { Write-Host "`n新增记录：" -ForegroundColor Green; $added | ForEach-Object { Write-Host "  + $_" } }
    if ($removed) { Write-Host "`n删除记录：" -ForegroundColor Red; $removed | ForEach-Object { Write-Host "  - $_" } }
}

Compare-CsvData -ReferenceFile "C:\Data\servers-old.csv" -DifferenceFile "C:\Data\servers-new.csv" -KeyColumn "ServerName"
```

执行结果示例：

```
CSV 对比结果：
  新增：3 条
  删除：1 条
  共有：47 条

新增记录：
  + SRV-NEW-01
  + SRV-NEW-02
  + SRV-NEW-03

删除记录：
  - SRV-OLD-05
```

## 注意事项

1. **编码问题**：`Import-Csv` 在 PowerShell 5.1 中默认使用 ANSI 编码，中文 CSV 务必指定 `-Encoding UTF8`
2. **引号处理**：CSV 中包含逗号的字段应该用双引号包裹，`Import-Csv` 会自动处理
3. **大文件性能**：`Import-Csv` 会将整个文件加载到内存，超大文件使用流式处理
4. **类型转换**：CSV 所有值都是字符串，数值比较和计算前需要显式转换类型
5. **NoTypeInformation**：`Export-Csv` 务必加 `-NoTypeInformation`，否则第一行会输出 .NET 类型信息
6. **日期格式**：CSV 中的日期格式不统一时，使用 `[datetime]::ParseExact()` 指定格式解析
