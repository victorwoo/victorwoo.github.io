---
layout: post
date: 2024-08-09 08:00:00
title: "PowerShell 技能连载 - Excel 文件处理技巧"
description: PowerTip of the Day - PowerShell Excel File Handling Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中处理 Excel 文件是一项常见任务，特别是在处理报表、数据分析时。本文将介绍一些实用的 Excel 文件处理技巧。

首先，我们需要安装必要的模块：

```powershell
# 安装 Excel 处理模块
Install-Module -Name ImportExcel -Force
```

创建和写入 Excel 文件：

```powershell
# 创建示例数据
$data = @(
    [PSCustomObject]@{
        姓名 = "张三"
        部门 = "技术部"
        职位 = "高级工程师"
        入职日期 = "2020-01-15"
        薪资 = 15000
    },
    [PSCustomObject]@{
        姓名 = "李四"
        部门 = "市场部"
        职位 = "市场经理"
        入职日期 = "2019-06-20"
        薪资 = 12000
    }
)

# 导出到 Excel 文件
$data | Export-Excel -Path "employees.xlsx" -WorksheetName "员工信息" -AutoSize
```

读取 Excel 文件：

```powershell
# 读取 Excel 文件
$employees = Import-Excel -Path "employees.xlsx" -WorksheetName "员工信息"

# 显示数据
Write-Host "员工列表："
$employees | Format-Table
```

处理多个工作表：

```powershell
# 创建包含多个工作表的 Excel 文件
$data1 = @(
    [PSCustomObject]@{ 产品 = "笔记本电脑"; 价格 = 5999; 库存 = 10 }
    [PSCustomObject]@{ 产品 = "无线鼠标"; 价格 = 199; 库存 = 50 }
)

$data2 = @(
    [PSCustomObject]@{ 客户 = "公司A"; 订单号 = "ORD001"; 金额 = 10000 }
    [PSCustomObject]@{ 客户 = "公司B"; 订单号 = "ORD002"; 金额 = 8000 }
)

# 导出到不同的工作表
$data1 | Export-Excel -Path "inventory.xlsx" -WorksheetName "库存" -AutoSize
$data2 | Export-Excel -Path "inventory.xlsx" -WorksheetName "订单" -AutoSize
```

格式化 Excel 文件：

```powershell
# 创建带格式的 Excel 文件
$data = @(
    [PSCustomObject]@{ 姓名 = "张三"; 销售额 = 15000; 完成率 = 0.85 }
    [PSCustomObject]@{ 姓名 = "李四"; 销售额 = 12000; 完成率 = 0.75 }
    [PSCustomObject]@{ 姓名 = "王五"; 销售额 = 18000; 完成率 = 0.95 }
)

# 导出并应用格式
$excel = $data | Export-Excel -Path "sales.xlsx" -WorksheetName "销售报表" -AutoSize -PassThru

# 设置列宽
$excel.Workbook.Worksheets["销售报表"].Column(1).Width = 15
$excel.Workbook.Worksheets["销售报表"].Column(2).Width = 15
$excel.Workbook.Worksheets["销售报表"].Column(3).Width = 15

# 设置数字格式
$excel.Workbook.Worksheets["销售报表"].Column(2).Style.Numberformat.Format = "#,##0"
$excel.Workbook.Worksheets["销售报表"].Column(3).Style.Numberformat.Format = "0.00%"

# 保存更改
Close-ExcelPackage $excel
```

一些实用的 Excel 处理技巧：

1. 合并多个 Excel 文件：
```powershell
# 合并多个 Excel 文件的工作表
$excelFiles = Get-ChildItem -Path "*.xlsx" -Filter "sales_*.xlsx"
$combinedData = @()
foreach ($file in $excelFiles) {
    $combinedData += Import-Excel -Path $file.FullName
}
$combinedData | Export-Excel -Path "combined_sales.xlsx" -WorksheetName "合并数据" -AutoSize
```

2. 数据筛选和过滤：
```powershell
# 读取 Excel 并过滤数据
$data = Import-Excel -Path "employees.xlsx"
$highSalary = $data | Where-Object { $_.薪资 -gt 12000 }
$highSalary | Export-Excel -Path "high_salary.xlsx" -WorksheetName "高薪员工" -AutoSize
```

3. 创建数据透视表：
```powershell
# 创建数据透视表
$data = Import-Excel -Path "sales.xlsx"
$pivotTable = $data | Pivot-Table -PivotRows 部门 -PivotValues 销售额 -PivotColumns 月份
$pivotTable | Export-Excel -Path "sales_pivot.xlsx" -WorksheetName "数据透视表" -AutoSize
```

这些技巧将帮助您更有效地处理 Excel 文件。记住，在处理大型 Excel 文件时，考虑使用流式处理方法来优化内存使用。同时，始终注意数据的完整性和格式的正确性。 