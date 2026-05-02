---
layout: post
date: 2025-08-11 08:00:00
updated: 2025-08-11 08:00:00
title: "PowerShell 技能连载 - 对 CSV 执行 SQL 风格查询"
description: PowerTip of the Day - SQL-Style Queries Against CSV Files in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- csv
- sql
- data-query
- ado-net
---

_适用于 PowerShell 5.1 及以上版本_

在日常运维和数据处理工作中，CSV 是最常见的文件格式之一。日志导出、监控报表、资产清单等数据通常都以 CSV 形式存储。虽然 PowerShell 原生的 `Import-Csv` 配合 `Where-Object`、`Sort-Object`、`Select-Object` 可以完成基本的数据筛选，但当查询逻辑复杂时——多表关联、聚合统计、分组排序——原生管道写法既冗长又难以维护。

SQL 作为数据查询的标准语言，其表达力远超管道命令。借助 .NET 内置的 OleDb 或 JDBC 方式，PowerShell 可以直接对 CSV 文件执行 SQL 查询语句，从而用熟悉的 SELECT、JOIN、GROUP BY 语法完成复杂的数据分析任务，性能也比管道过滤高出不少。

本文将介绍三种在 PowerShell 中对 CSV 执行 SQL 查询的方式：OLE DB Provider、ADO.NET 内存表，以及第三方模块。

<!-- more -->

## 方式一：使用 OLE DB Provider 查询 CSV

Windows 系统内置的 Microsoft.ACE.OLEDB 提供程序可以直接将 CSV 文件当作数据库表来查询。这种方式性能优秀，适合处理大量数据。

首先创建示例 CSV 文件用于后续演示。

```powershell
# 创建示例 CSV：员工信息表
$employeeCsv = @"
Id,Name,Department,Salary,City
1,张三,工程部,25000,北京
2,李四,市场部,18000,上海
3,王五,工程部,30000,北京
4,赵六,人事部,15000,广州
5,钱七,市场部,22000,深圳
6,孙八,工程部,28000,北京
7,周九,人事部,16000,上海
8,吴十,市场部,20000,广州
"@ | Out-String

$employeeCsv.Trim() | Set-Content -Path ".\employees.csv" -Encoding UTF8

# 创建示例 CSV：部门预算表
$budgetCsv = @"
Department,Budget,Year
工程部,500000,2025
市场部,300000,2025
人事部,150000,2025
"@ | Out-String

$budgetCsv.Trim() | Set-Content -Path ".\budgets.csv" -Encoding UTF8

Write-Host "示例 CSV 文件已创建"
```

执行结果示例：

```text
示例 CSV 文件已创建
```

接下来使用 OLE DB 连接 CSV 文件并执行 SQL 查询。

```powershell
function Invoke-CsvSqlQuery {
    param(
        [Parameter(Mandatory)]
        [string[]]$CsvPath,

        [Parameter(Mandatory)]
        [string]$Query,

        [string]$Delimiter = ","
    )

    # 获取 CSV 文件所在目录作为数据源
    $directory = (Resolve-Path (Split-Path $CsvPath[0] -Parent)).Path

    # 构建 OLE DB 连接字符串
    $connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$directory;Extended Properties=`"Text;HDR=YES;FMT=Delimited($Delimiter);Charset=UTF8`""

    try {
        $connection = New-Object System.Data.OleDb.OleDbConnection($connectionString)
        $connection.Open()

        $command = New-Object System.Data.OleDb.OleDbCommand($Query, $connection)
        $adapter = New-Object System.Data.OleDb.OleDbDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null

        $dataset.Tables[0]
    }
    finally {
        if ($connection.State -eq 'Open') {
            $connection.Close()
        }
    }
}

# 查询薪资大于 20000 的员工
$results = Invoke-CsvSqlQuery -CsvPath ".\employees.csv" -Query "SELECT Name, Department, Salary FROM employees.csv WHERE Salary > 20000 ORDER BY Salary DESC"
$results | Format-Table -AutoSize
```

执行结果示例：

```text
Name Department Salary
---- ---------- ------
王五 工程部       30000
孙八 工程部       28000
钱七 市场部       22000
```

## 方式二：使用 DataTable 内存查询

当 OLE DB 提供程序不可用时（例如在非 Windows 系统或没有安装 ACE 组件的环境中），可以将 CSV 导入 DataTable 后使用 `DataTable.Select()` 方法执行 SQL 风格的过滤表达式。

```powershell
function Invoke-CsvDataTableQuery {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [string]$FilterExpression,

        [string[]]$SortColumns
    )

    # 将 CSV 导入 DataTable
    $data = Import-Csv -Path $CsvPath
    $dataTable = [System.Data.DataTable]::new("CsvData")

    # 根据第一行数据推断列类型
    $firstRow = $data[0]
    foreach ($property in $firstRow.PSObject.Properties) {
        $column = [System.Data.DataColumn]::new($property.Name)
        $dataTable.Columns.Add($column)
    }

    # 填充数据行
    foreach ($row in $data) {
        $dataRow = $dataTable.NewRow()
        foreach ($property in $row.PSObject.Properties) {
            $dataRow[$property.Name] = $property.Value
        }
        $dataTable.Rows.Add($dataRow)
    }

    # 执行查询
    $sortExpression = if ($SortColumns) { $SortColumns -join ", " } else { $null }
    $dataTable.Select($FilterExpression, $sortExpression) |
        ForEach-Object {
            $hashtable = @{}
            foreach ($col in $dataTable.Columns.ColumnName) {
                $hashtable[$col] = $_[$col]
            }
            [PSCustomObject]$hashtable
        }
}

# 查询北京的工程部员工并按薪资降序排列
$results = Invoke-CsvDataTableQuery -CsvPath ".\employees.csv" -FilterExpression "City = '北京' AND Department = '工程部'" -SortColumns "Salary DESC"
$results | Format-Table -AutoSize
```

执行结果示例：

```textName Department Salary City
---- ---------- ------ ----
王五 工程部       30000 北京
孙八 工程部       28000 北京
张三 工程部       25000 北京
```

## 方式三：实现聚合与分组统计

结合 DataTable 方式，我们可以进一步实现 GROUP BY 和聚合函数的效果。以下函数支持对 CSV 数据执行分组统计。

```powershell
function Get-CsvAggregate {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [string]$GroupByColumn,

        [ValidateSet("Sum", "Average", "Count", "Min", "Max")]
        [string]$AggregateFunction = "Count",

        [string]$AggregateColumn
    )

    $data = Import-Csv -Path $CsvPath

    # 验证聚合列是否存在
    if ($AggregateColumn -and $AggregateFunction -ne "Count") {
        $sample = $data[0].PSObject.Properties.Name
        if ($AggregateColumn -notin $sample) {
            throw "列 '$AggregateColumn' 在 CSV 中不存在。可用列: $($sample -join ', ')"
        }
    }

    # 分组
    $groups = $data | Group-Object -Property $GroupByColumn

    $results = foreach ($group in $groups) {
        $aggregateValue = switch ($AggregateFunction) {
            "Count" { $group.Count }
            "Sum"   { ($group.Group | Measure-Object -Property $AggregateColumn -Sum).Sum }
            "Average" { [math]::Round(($group.Group | Measure-Object -Property $AggregateColumn -Average).Average, 2) }
            "Min"   { ($group.Group | Measure-Object -Property $AggregateColumn -Minimum).Minimum }
            "Max"   { ($group.Group | Measure-Object -Property $AggregateColumn -Maximum).Maximum }
        }

        [PSCustomObject]@{
            $GroupByColumn     = $group.Name
            "$AggregateFunction`($AggregateColumn)" = $aggregateValue
            RecordCount        = $group.Count
        }
    }

    $results
}

# 按部门统计平均薪资
Write-Host "`n=== 按部门统计平均薪资 ==="
Get-CsvAggregate -CsvPath ".\employees.csv" -GroupByColumn Department -AggregateFunction Average -AggregateColumn Salary |
    Format-Table -AutoSize

# 按城市统计人数
Write-Host "`n=== 按城市统计人数 ==="
Get-CsvAggregate -CsvPath ".\employees.csv" -GroupByColumn City -AggregateFunction Count |
    Format-Table -AutoSize
```

执行结果示例：

```text
=== 按部门统计平均薪资 ===

Department  Average(Salary) RecordCount
----------  --------------- -----------
工程部              27666.67           3
市场部              20000              3
人事部              15500              2

=== 按城市统计人数 ===

City  Count() RecordCount
----  ------- -----------
北京         3           3
上海         2           2
广州         2           2
深圳         1           1
```

## 方式四：模拟 JOIN 关联查询

将两个 CSV 文件关联起来是常见需求。以下函数模拟了 SQL 的 INNER JOIN 操作。

```powershell
function Join-CsvData {
    param(
        [Parameter(Mandatory)]
        [string]$LeftCsvPath,

        [Parameter(Mandatory)]
        [string]$RightCsvPath,

        [Parameter(Mandatory)]
        [string]$LeftJoinColumn,

        [Parameter(Mandatory)]
        [string]$RightJoinColumn,

        [ValidateSet("Inner", "Left")]
        [string]$JoinType = "Inner"
    )

    $leftData = Import-Csv -Path $LeftCsvPath
    $rightData = Import-Csv -Path $RightCsvPath

    # 构建右侧数据的哈希表索引
    $rightIndex = @{}
    foreach ($rightRow in $rightData) {
        $key = $rightRow.$RightJoinColumn
        if (-not $rightIndex.ContainsKey($key)) {
            $rightIndex[$key] = @()
        }
        $rightIndex[$key] += $rightRow
    }

    # 获取列名集合
    $leftColumns = $leftData[0].PSObject.Properties.Name
    $rightColumns = $rightData[0].PSObject.Properties.Name | Where-Object { $_ -ne $RightJoinColumn }

    $results = foreach ($leftRow in $leftData) {
        $key = $leftRow.$LeftJoinColumn
        $matched = $rightIndex[$key]

        if ($matched) {
            foreach ($rightRow in $matched) {
                $row = [ordered]@{}
                foreach ($col in $leftColumns) {
                    $row[$col] = $leftRow.$col
                }
                foreach ($col in $rightColumns) {
                    $row[$col] = $rightRow.$col
                }
                [PSCustomObject]$row
            }
        }
        elseif ($JoinType -eq "Left") {
            $row = [ordered]@{}
            foreach ($col in $leftColumns) {
                $row[$col] = $leftRow.$col
            }
            foreach ($col in $rightColumns) {
                $row[$col] = $null
            }
            [PSCustomObject]$row
        }
    }

    $results
}

# 关联员工表和部门预算表
Write-Host "`n=== 员工与部门预算关联 ==="
Join-CsvData -LeftCsvPath ".\employees.csv" -RightCsvPath ".\budgets.csv" -LeftJoinColumn Department -RightJoinColumn Department |
    Format-Table Name, Department, Salary, Budget -AutoSize
```

执行结果示例：

```text
=== 员工与部门预算关联 ===

Name Department Salary Budget
---- ---------- ------ ------
张三 工程部       25000 500000
李四 市场部       18000 300000
王五 工程部       30000 500000
赵六 人事部       15000 150000
钱七 市场部       22000 300000
孙八 工程部       28000 500000
周九 人事部       16000 150000
吴十 市场部       20000 300000
```

## 实战场景：分析 IIS 日志

以下是一个实际运维场景：将 IIS 日志转换为 CSV 后执行 SQL 查询，快速统计访问热点和异常状态码。

```powershell
function Get-IisLogStatistics {
    param(
        [Parameter(Mandatory)]
        [string]$LogFilePath,

        [int]$TopN = 10
    )

    # 解析 IIS 日志（跳过注释行）
    $logData = Get-Content -Path $LogFilePath |
        Where-Object { $_ -notlike "#*" -and $_.Trim() -ne "" } |
        ConvertFrom-Csv -Delimiter " "

    Write-Host "`n=== 状态码分布 ==="
    $logData | Group-Object -Property "sc-status" |
        Sort-Object Count -Descending |
        Select-Object Count, Name -First 5 |
        Format-Table @{Label="次数"; Expression={$_.Count}}, @{Label="状态码"; Expression={$_.Name}} -AutoSize

    Write-Host "`n=== 访问量前 $TopN 的 URI ==="
    $logData | Group-Object -Property "cs-uri-stem" |
        Sort-Object Count -Descending |
        Select-Object Count, Name -First $TopN |
        Format-Table @{Label="次数"; Expression={$_.Count}}, @{Label="URI"; Expression={$_.Name}} -AutoSize

    Write-Host "`n=== 5xx 错误详情 ==="
    $logData | Where-Object { $_."sc-status" -like "5*" } |
        Select-Object -First $TopN |
        Format-Table date, time, "c-ip", "cs-method", "cs-uri-stem", "sc-status" -AutoSize
}

# 模拟 IIS 日志进行分析（实际使用时传入真实日志路径）
$logContent = @"
date time c-ip cs-method cs-uri-stem sc-status time-taken
2025-08-11 08:01:10 192.168.1.100 GET /api/users 200 45
2025-08-11 08:01:11 192.168.1.101 GET /api/orders 500 1200
2025-08-11 08:01:12 192.168.1.100 GET /api/users 200 38
2025-08-11 08:01:13 10.0.0.50 POST /api/login 401 15
2025-08-11 08:01:14 192.168.1.102 GET /api/products 200 92
2025-08-11 08:01:15 192.168.1.101 GET /api/orders 503 3500
"@

$logContent | Set-Content -Path ".\iis-test.log" -Encoding UTF8
Get-IisLogStatistics -LogFilePath ".\iis-test.log" -TopN 5
```

执行结果示例：

```text
=== 状态码分布 ===
次数 状态码
---- ------
   3 200
   2 500
   1 401

=== 访问量前 5 的 URI ===
次数 URI
---- ---
   2 /api/users
   2 /api/orders
   1 /api/login
   1 /api/products

=== 5xx 错误详情 ===
date       time     c-ip         cs-method cs-uri-stem  sc-status time-taken
----       ----     ----         --------- -----------  --------- ----------
2025-08-11 08:01:11 192.168.1.101 GET       /api/orders  500       1200
2025-08-11 08:01:15 192.168.1.101 GET       /api/orders  503       3500
```

## 注意事项

1. **OLE DB 提供程序依赖**：Microsoft.ACE.OLEDB.12.0 需要在 Windows 上安装 Microsoft Access Database Engine，64 位 PowerShell 需要安装 64 位版本的引擎。如果系统没有安装，可以使用 DataTable 方式作为替代方案。

2. **CSV 文件编码问题**：OLE DB Provider 对 CSV 的编码支持有限，包含中文的 CSV 文件建议使用 UTF-8 with BOM 编码，否则可能出现乱码。可以在 schema.ini 文件中指定字符集。

3. **内存消耗**：DataTable 方式将整个 CSV 加载到内存，处理超大文件（数百 MB 以上）时可能导致内存不足。对于大数据量场景，建议使用流式处理或分批加载。

4. **列类型推断**：CSV 是纯文本格式，所有值都是字符串。进行数值比较或聚合计算时，需要确保数据能正确转换为数值类型，否则 SUM、AVG 等操作会失败。

5. **SQL 注入风险**：如果 SQL 查询语句中包含用户输入的内容，务必进行参数化处理或严格的输入验证，防止 SQL 注入攻击。尤其是在将脚本发布为共享工具时。

6. **性能对比**：对于简单过滤（单列、单条件），PowerShell 原生管道 (`Where-Object`) 的性能足够；对于复杂查询（多表关联、聚合统计），SQL 方式在代码可读性和执行效率上都有明显优势。根据实际场景选择合适的方式。
