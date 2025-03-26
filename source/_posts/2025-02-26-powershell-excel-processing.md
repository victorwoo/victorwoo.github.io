---
layout: post
date: 2025-02-26 08:00:00
title: "PowerShell 技能连载 - Excel 处理技巧"
description: PowerTip of the Day - PowerShell Excel Processing Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 Excel 文件是一项常见任务，本文将介绍一些实用的 Excel 处理技巧。

首先，让我们看看基本的 Excel 操作：

```powershell
# 创建 Excel 信息获取函数
function Get-ExcelInfo {
    param(
        [string]$ExcelPath
    )
    
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Open($ExcelPath)
        
        $info = [PSCustomObject]@{
            FileName = Split-Path $ExcelPath -Leaf
            SheetCount = $workbook.Sheets.Count
            SheetNames = $workbook.Sheets | ForEach-Object { $_.Name }
            UsedRange = $workbook.Sheets(1).UsedRange.Address
        }
        
        $workbook.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
        
        return $info
    }
    catch {
        Write-Host "获取 Excel 信息失败：$_"
    }
}
```

Excel 数据导出：

```powershell
# 创建 Excel 数据导出函数
function Export-ExcelData {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$SheetName,
        [int]$StartRow = 1,
        [int]$EndRow
    )
    
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Open($InputPath)
        $sheet = $workbook.Sheets($SheetName)
        
        if (-not $EndRow) {
            $EndRow = $sheet.UsedRange.Rows.Count
        }
        
        $data = @()
        for ($row = $StartRow; $row -le $EndRow; $row++) {
            $rowData = @()
            for ($col = 1; $col -le $sheet.UsedRange.Columns.Count; $col++) {
                $rowData += $sheet.Cells($row, $col).Text
            }
            $data += $rowData -join ","
        }
        
        $data | Out-File $OutputPath -Encoding UTF8
        
        $workbook.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
        
        Write-Host "数据导出完成：$OutputPath"
    }
    catch {
        Write-Host "导出失败：$_"
    }
}
```

Excel 数据导入：

```powershell
# 创建 Excel 数据导入函数
function Import-ExcelData {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [string]$SheetName = "Sheet1",
        [string[]]$Headers
    )
    
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Add()
        $sheet = $workbook.Sheets(1)
        $sheet.Name = $SheetName
        
        # 写入表头
        for ($i = 0; $i -lt $Headers.Count; $i++) {
            $sheet.Cells(1, $i + 1) = $Headers[$i]
        }
        
        # 写入数据
        $row = 2
        Get-Content $InputPath | ForEach-Object {
            $values = $_ -split ","
            for ($col = 0; $col -lt $values.Count; $col++) {
                $sheet.Cells($row, $col + 1) = $values[$col]
            }
            $row++
        }
        
        # 调整列宽
        $sheet.UsedRange.EntireColumn.AutoFit()
        
        $workbook.SaveAs($OutputPath)
        $workbook.Close($true)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
        
        Write-Host "数据导入完成：$OutputPath"
    }
    catch {
        Write-Host "导入失败：$_"
    }
}
```

Excel 数据合并：

```powershell
# 创建 Excel 数据合并函数
function Merge-ExcelData {
    param(
        [string[]]$InputFiles,
        [string]$OutputPath,
        [string]$SheetName = "Sheet1"
    )
    
    try {
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Add()
        $sheet = $workbook.Sheets(1)
        $sheet.Name = $SheetName
        
        $currentRow = 1
        $headersWritten = $false
        
        foreach ($file in $InputFiles) {
            $sourceWorkbook = $excel.Workbooks.Open($file)
            $sourceSheet = $sourceWorkbook.Sheets(1)
            
            if (-not $headersWritten) {
                # 复制表头
                $sourceSheet.Range($sourceSheet.UsedRange.Rows(1).Address).Copy($sheet.Cells($currentRow, 1))
                $headersWritten = $true
                $currentRow++
            }
            
            # 复制数据
            $lastRow = $sourceSheet.UsedRange.Rows.Count
            if ($lastRow -gt 1) {
                $sourceSheet.Range($sourceSheet.UsedRange.Rows(2).Address + ":" + $sourceSheet.UsedRange.Rows($lastRow).Address).Copy($sheet.Cells($currentRow, 1))
                $currentRow += $lastRow - 1
            }
            
            $sourceWorkbook.Close($false)
        }
        
        # 调整列宽
        $sheet.UsedRange.EntireColumn.AutoFit()
        
        $workbook.SaveAs($OutputPath)
        $workbook.Close($true)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
        
        Write-Host "数据合并完成：$OutputPath"
    }
    catch {
        Write-Host "合并失败：$_"
    }
}
```

这些技巧将帮助您更有效地处理 Excel 文件。记住，在处理 Excel 时，始终要注意内存管理和资源释放。同时，建议在处理大型 Excel 文件时使用流式处理方式，以提高性能。 