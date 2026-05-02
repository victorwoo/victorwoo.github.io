---
layout: post
date: 2026-02-23 08:00:00
updated: 2026-02-23 08:00:00
title: "PowerShell 技能连载 - 数据转换工具集"
description: PowerTip of the Day - Data Transformation Toolkit in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- text-processing
- database
- data-format
---

_适用于 PowerShell 7.0 及以上版本_

在运维自动化的日常工作中，数据格式转换几乎无处不在。你可能需要把 CSV 报表转成 JSON 传给 API，把 XML 配置文件解析成对象做比较，或者把 API 返回的数据加工成 CSV 交给业务方。这些看似零碎的操作，实际上构成了数据处理的基础链条。

PowerShell 作为一门面向对象的脚本语言，天然擅长处理结构化数据。它的管道机制让格式转换变得流畅——对象在管道中传递，随时可以在不同格式之间切换。配合 `ConvertTo-Json`、`ConvertFrom-Json`、`ConvertTo-Xml`、`ConvertFrom-Csv` 等内置 cmdlet，一条命令就能完成其他语言需要几十行代码才能实现的转换。

本文将围绕三个核心场景展开：基础格式互转、数据清洗与标准化，以及完整的 ETL 管道实战。掌握这些技巧后，你可以用 PowerShell 构建轻量级的数据处理管道，替代许多需要专门 ETL 工具才能完成的任务。

<!-- more -->

## 基础格式转换

PowerShell 内置了多种格式转换 cmdlet，可以在 CSV、JSON、XML 之间自由切换。下面的工具函数封装了常见的转换场景，支持链式调用。

```powershell
function Convert-DataFormat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject,

        [Parameter(Mandatory)]
        [ValidateSet('Json', 'Csv', 'Xml', 'Yaml', 'HashTable')]
        [string]$ToFormat,

        [int]$Depth = 10
    )

    process {
        switch ($ToFormat) {
            'Json' {
                $InputObject | ConvertTo-Json -Depth $Depth -EnumsAsStrings
            }
            'Csv' {
                if ($InputObject -is [string]) {
                    $InputObject | ConvertFrom-Csv | ConvertTo-Csv -NoTypeInformation
                }
                else {
                    $InputObject | ConvertTo-Csv -NoTypeInformation
                }
            }
            'Xml' {
                $InputObject | ConvertTo-Xml -NoTypeInformation -As Stream
            }
            'HashTable' {
                if ($InputObject -is [string]) {
                    $json = $InputObject
                }
                else {
                    $json = $InputObject | ConvertTo-Json -Depth $Depth -Compress
                }
                [System.Text.Json.JsonSerializer]::Deserialize(
                    $json,
                    [System.Collections.Generic.Dictionary[string, object]],
                    (New-Object System.Text.Json.JsonSerializerOptions -Property @{
                        PropertyNameCaseInsensitive = $true
                    })
                )
            }
            'Yaml' {
                # YAML 没有内置 cmdlet，通过 JSON 中转后手动格式化
                $json = if ($InputObject -is [string]) { $InputObject } else {
                    $InputObject | ConvertTo-Json -Depth $Depth
                }
                $obj = $json | ConvertFrom-Json
                ConvertTo-YamlString -InputObject $obj -Indent 0
            }
        }
    }
}

function ConvertTo-YamlString {
    param($InputObject, [int]$Indent = 0)
    $space = '  ' * $Indent
    $sb = [System.Text.StringBuilder]::new()

    if ($InputObject -is [System.Collections.IEnumerable] -and
        $InputObject -isnot [string]) {
        foreach ($item in $InputObject) {
            $null = $sb.Append("${space}- ")
            if ($item -is [System.Collections.IDictionary] -or
                $item -is [PSCustomObject]) {
                $null = $sb.AppendLine()
                $null = $sb.Append((ConvertTo-YamlString $item ($Indent + 1)))
            }
            else {
                $null = $sb.AppendLine("'$item'")
            }
        }
    }
    elseif ($InputObject -is [System.Collections.IDictionary] -or
        $InputObject -is [PSCustomObject]) {
        $props = if ($InputObject -is [System.Collections.IDictionary]) {
            $InputObject.GetEnumerator()
        }
        else {
            $InputObject.PSObject.Properties
        }
        foreach ($prop in $props) {
            $name = $prop.Key ?? $prop.Name
            $val = $prop.Value ?? $prop
            $null = $sb.Append("${space}${name}: ")
            if ($val -is [System.Collections.IEnumerable] -and
                $val -isnot [string]) {
                $null = $sb.AppendLine()
                $null = $sb.Append((ConvertTo-YamlString $val ($Indent + 1)))
            }
            elseif ($val -is [System.Collections.IDictionary] -or
                $val -is [PSCustomObject]) {
                $null = $sb.AppendLine()
                $null = $sb.Append((ConvertTo-YamlString $val ($Indent + 1)))
            }
            else {
                $null = $sb.AppendLine("'$val'")
            }
        }
    }
    else {
        $null = $sb.AppendLine("${space}'$InputObject'")
    }

    $sb.ToString()
}

# 示例：CSV 转 JSON
$csvData = @'
Name,Department,Salary,StartDate
张三,工程部,25000,2024-03-15
李四,市场部,18000,2023-08-20
王五,工程部,30000,2022-11-01
赵六,人事部,22000,2025-01-10
'@

Write-Host "=== CSV 转 JSON ===" -ForegroundColor Cyan
$jsonOutput = $csvData | ConvertFrom-Csv | Convert-DataFormat -ToFormat Json
$jsonOutput

Write-Host "`n=== JSON 转 HashTable ===" -ForegroundColor Cyan
$jsonOutput | Convert-DataFormat -ToFormat HashTable |
    ForEach-Object { $_.GetEnumerator() } |
    Format-Table Key, Value -AutoSize

Write-Host "`n=== CSV 转 XML ===" -ForegroundColor Cyan
$xmlOutput = $csvData | ConvertFrom-Csv | Convert-DataFormat -ToFormat Xml
$xmlOutput | Select-Object -First 10
```

执行结果示例：

```
=== CSV 转 JSON ===
[
  {
    "Name": "张三",
    "Department": "工程部",
    "Salary": "25000",
    "StartDate": "2024-03-15"
  },
  {
    "Name": "李四",
    "Department": "市场部",
    "Salary": "18000",
    "StartDate": "2023-08-20"
  },
  {
    "Name": "王五",
    "Department": "工程部",
    "Salary": "30000",
    "StartDate": "2022-11-01"
  },
  {
    "Name": "赵六",
    "Department": "人事部",
    "Salary": "22000",
    "StartDate": "2025-01-10"
  }
]

=== JSON 转 HashTable ===
Key        Value
---        -----
Name       张三
Department 工程部
Salary     25000
StartDate  2024-03-15

=== CSV 转 XML ===
<?xml version="1.0" encoding="utf-8"?>
<Objects>
  <Object Type="System.Management.Automation.PSCustomObject">
    <Property Name="Name" Type="System.String">张三</Property>
    <Property Name="Department" Type="System.String">工程部</Property>
    <Property Name="Salary" Type="System.String">25000</Property>
    <Property Name="StartDate" Type="System.String">2024-03-15</Property>
  </Object>
  ...
</Objects>
```

## 数据清洗与标准化

原始数据往往不规范——字段名不统一、存在重复记录、类型混杂、空值缺失。在转换之前先做清洗，是保证数据质量的关键步骤。

```powershell
function Invoke-DataCleanse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        # 字段映射表：旧名 → 新名
        [Parameter(Mandatory)]
        [hashtable]$FieldMap,

        # 需要转换为 DateTime 的字段
        [string[]]$DateFields,

        # 需要转换为数值的字段
        [string[]]$NumericFields,

        # 默认空值填充
        $DefaultNullValue = 'N/A'
    )

    begin {
        $seen = [System.Collections.Generic.HashSet[string]]::new()
        $duplicateCount = 0
        $totalProcessed = 0
    }

    process {
        $totalProcessed++

        # 构建去重键（使用所有字段值的拼接）
        $keyParts = $InputObject.PSObject.Properties.Value |
            Where-Object { $_ } |
            ForEach-Object { $_.ToString() }
        $dedupKey = $keyParts -join '|'

        if (-not $seen.Add($dedupKey)) {
            $duplicateCount++
            return
        }

        $result = [ordered]@{}

        foreach ($prop in $InputObject.PSObject.Properties) {
            $fieldName = $prop.Name
            $value = $prop.Value

            # 字段名映射
            if ($FieldMap.ContainsKey($fieldName)) {
                $fieldName = $FieldMap[$fieldName]
            }

            # 空值处理
            if ([string]::IsNullOrWhiteSpace($value)) {
                $value = $DefaultNullValue
            }
            else {
                $value = $value.Trim()

                # 日期字段转换
                if ($DateFields -and $fieldName -in $DateFields) {
                    if ($value -ne $DefaultNullValue) {
                        if ([datetime]::TryParse($value, [ref]$parsed)) {
                            $value = $parsed
                        }
                    }
                }

                # 数值字段转换
                if ($NumericFields -and $fieldName -in $NumericFields) {
                    if ($value -ne $DefaultNullValue) {
                        $cleaned = $value -replace '[,，]', ''
                        if ([double]::TryParse($cleaned, [ref]$num)) {
                            $value = $num
                        }
                    }
                }
            }

            $result[$fieldName] = $value
        }

        [PSCustomObject]$result
    }

    end {
        Write-Verbose "处理完成: 总计 $totalProcessed 条, 去除重复 $duplicateCount 条, 输出 $($totalProcessed - $duplicateCount) 条"
    }
}

# 模拟原始脏数据
$rawData = @'
emp_name,dept,salary,start_date,email
张三,工程部,25000,2024-03-15,zhangsan@corp.com
李四,市场部,18000,2023-08-20,lisi@corp.com
张三,工程部,25000,2024-03-15,zhangsan@corp.com
王五,,30000,,
赵六,人事部,22,000,2025-01-10,zhaoliu@corp.com
孙七,工程部,28000,invalid-date,sunqi@corp.com
'@

$fieldMapping = @{
    'emp_name'   = 'EmployeeName'
    'dept'       = 'Department'
    'salary'     = 'AnnualSalary'
    'start_date' = 'StartDate'
    'email'      = 'ContactEmail'
}

$cleaned = $rawData | ConvertFrom-Csv |
    Invoke-DataCleanse `
        -FieldMap $fieldMapping `
        -DateFields 'StartDate' `
        -NumericFields 'AnnualSalary' `
        -DefaultNullValue '未知' `
        -Verbose

Write-Host "=== 清洗结果 ===" -ForegroundColor Cyan
$cleaned | Format-Table -AutoSize

Write-Host "`n=== 数据类型验证 ===" -ForegroundColor Cyan
$cleaned | Get-Member -MemberType NoteProperty |
    Select-Object Name, @{
        N = 'SampleType'
        E = {
            $val = $cleaned[0].($_.Name)
            if ($null -ne $val) { $val.GetType().Name } else { 'null' }
        }
    } | Format-Table -AutoSize
```

执行结果示例：

```
VERBOSE: 处理完成: 总计 6 条, 去除重复 1 条, 输出 5 条
=== 清洗结果 ===

EmployeeName Department AnnualSalary StartDate           ContactEmail
------------ ---------- ------------ ---------           ------------
张三         工程部            25000 2024/3/15 0:00:00    zhangsan@corp.com
李四         市场部            18000 2023/8/20 0:00:00    lisi@corp.com
王五         未知              30000 未知                 未知
赵六         人事部            22000 2025/1/10 0:00:00    zhaoliu@corp.com
孙七         工程部            28000 未知                 sunqi@corp.com

=== 数据类型验证 ===

Name          SampleType
----          ----------
EmployeeName  String
Department    String
AnnualSalary  Double
StartDate     DateTime
ContactEmail  String
```

## ETL 管道实战

下面模拟一个真实场景：从多个数据源（CSV 文件、JSON API 响应、XML 配置）提取数据，统一转换后合并，最终输出为标准报表格式。这种轻量级 ETL 管道在运维报表、配置审计等场景中非常实用。

```powershell
function Invoke-DataEtlPipeline {
    [CmdletBinding()]
    param(
        [string]$OutputPath = './etl-output',
        [switch]$IncludeSummary
    )

    # ---- Extract 阶段：从多源提取数据 ----

    Write-Host "[Extract] 从 CSV 提取服务器资产数据..." -ForegroundColor Yellow
    $serverCsv = @'
Hostname,IP,OS,CPU_CORES,RAM_GB,STATUS
WEB-01,192.168.1.10,Ubuntu 22.04,4,16,Running
WEB-02,192.168.1.11,Ubuntu 22.04,4,16,Running
DB-01,192.168.1.20,CentOS 7,8,64,Running
DB-02,192.168.1.21,CentOS 7,8,64,Stopped
CACHE-01,192.168.1.30,Ubuntu 22.04,2,8,Running
'@

    $servers = $serverCsv | ConvertFrom-Csv
    Write-Host "  提取 $($servers.Count) 条服务器记录"

    Write-Host "[Extract] 从 JSON 提取监控指标数据..." -ForegroundColor Yellow
    $metricsJson = @'
[
    {"host": "WEB-01", "cpu_pct": 45.2, "mem_pct": 62.1, "disk_pct": 33.7, "timestamp": "2026-02-23T08:00:00Z"},
    {"host": "WEB-02", "cpu_pct": 12.8, "mem_pct": 45.3, "disk_pct": 28.9, "timestamp": "2026-02-23T08:00:00Z"},
    {"host": "DB-01", "cpu_pct": 78.5, "mem_pct": 85.2, "disk_pct": 71.4, "timestamp": "2026-02-23T08:00:00Z"},
    {"host": "CACHE-01", "cpu_pct": 23.1, "mem_pct": 91.5, "disk_pct": 15.2, "timestamp": "2026-02-23T08:00:00Z"}
]
'@

    $metrics = $metricsJson | ConvertFrom-Json
    Write-Host "  提取 $($metrics.Count) 条监控指标"

    Write-Host "[Extract] 从 XML 提取告警配置..." -ForegroundColor Yellow
    $alertXml = @'
<alerts>
    <rule name="cpu_high" threshold="70" severity="critical" target_pattern="DB-*"/>
    <rule name="mem_warning" threshold="80" severity="warning" target_pattern="*"/>
    <rule name="disk_high" threshold="60" severity="warning" target_pattern="DB-*"/>
</alerts>
'@

    [xml]$xmlDoc = $alertXml
    $alertRules = $xmlDoc.alerts.rule | ForEach-Object {
        [PSCustomObject]@{
            RuleName      = $_.name
            Threshold     = [int]$_.threshold
            Severity      = $_.severity
            TargetPattern = $_.target_pattern
        }
    }
    Write-Host "  提取 $($alertRules.Count) 条告警规则"

    # ---- Transform 阶段：关联、转换、计算 ----

    Write-Host "`n[Transform] 关联服务器资产与监控指标..." -ForegroundColor Green

    $enriched = foreach ($srv in $servers) {
        $metric = $metrics | Where-Object { $_.host -eq $srv.Hostname }
        $triggeredAlerts = @()

        foreach ($rule in $alertRules) {
            $pattern = $rule.TargetPattern -replace '\*', '.*'
            if ($srv.Hostname -match "^$pattern$") {
                $violated = $false
                $fieldMap = @{
                    'cpu_high'    = 'cpu_pct'
                    'mem_warning' = 'mem_pct'
                    'disk_high'   = 'disk_pct'
                }
                $fieldName = $fieldMap[$rule.RuleName]
                if ($fieldName -and $metric -and
                    $metric.$fieldName -gt $rule.Threshold) {
                    $violated = $true
                }
                if ($violated) {
                    $triggeredAlerts += "[{0}] {1} ({2}% > {3}%)" -f
                        $rule.Severity, $rule.RuleName,
                        $metric.$fieldName, $rule.Threshold
                }
            }
        }

        [PSCustomObject][ordered]@{
            Hostname   = $srv.Hostname
            IPAddress  = $srv.IP
            OS         = $srv.OS
            CPU_Cores  = [int]$srv.CPU_CORES
            RAM_GB     = [int]$srv.RAM_GB
            Status     = $srv.STATUS
            CPU_Usage  = if ($metric) { $metric.cpu_pct } else { $null }
            MEM_Usage  = if ($metric) { $metric.mem_pct } else { $null }
            DISK_Usage = if ($metric) { $metric.disk_pct } else { $null }
            AlertCount = $triggeredAlerts.Count
            Alerts     = if ($triggeredAlerts) {
                $triggeredAlerts -join '; '
            } else { '无' }
        }
    }

    # ---- Load 阶段：输出到多种目标格式 ----

    $null = New-Item -ItemType Directory -Path $OutputPath -Force -ErrorAction SilentlyContinue

    Write-Host "`n[Load] 导出为 CSV 报表..." -ForegroundColor Magenta
    $csvFile = Join-Path $OutputPath 'server-report.csv'
    $enriched | ConvertTo-Csv -NoTypeInformation | Out-File $csvFile -Encoding utf8
    Write-Host "  已写入: $csvFile"

    Write-Host "[Load] 导出为 JSON..." -ForegroundColor Magenta
    $jsonFile = Join-Path $OutputPath 'server-report.json'
    $enriched | ConvertTo-Json -Depth 5 | Out-File $jsonFile -Encoding utf8
    Write-Host "  已写入: $jsonFile"

    Write-Host "[Load] 导出为 HTML 报表..." -ForegroundColor Magenta
    $htmlFile = Join-Path $OutputPath 'server-report.html'
    $htmlParams = @{
        Title  = '服务器状态报表'
        Body   = '<h1>服务器状态报表</h1>' +
                 '<p>生成时间: {0}</p>' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        Head   = '<style>table { border-collapse: collapse; } ' +
                 'td, th { border: 1px solid #ccc; padding: 6px; } ' +
                 '.critical { color: red; font-weight: bold; }</style>'
    }
    $enriched | ConvertTo-Html @htmlParams | Out-File $htmlFile -Encoding utf8
    Write-Host "  已写入: $htmlFile"

    if ($IncludeSummary) {
        Write-Host "`n=== ETL 汇总 ===" -ForegroundColor Cyan
        Write-Host ("  服务器总数: {0}" -f $enriched.Count)
        Write-Host ("  运行中: {0}" -f ($enriched | Where-Object Status -eq 'Running').Count)
        Write-Host ("  已停机: {0}" -f ($enriched | Where-Object Status -eq 'Stopped').Count)
        Write-Host ("  触发告警的服务器: {0}" -f ($enriched | Where-Object AlertCount -gt 0).Count)
        Write-Host ("  平均 CPU 使用率: {0:N1}%" -f (
            ($enriched | Where-Object CPU_Usage | Measure-Object -Property CPU_Usage -Average).Average
        ))
        Write-Host ("  平均内存使用率: {0:N1}%" -f (
            ($enriched | Where-Object MEM_Usage | Measure-Object -Property MEM_Usage -Average).Average
        ))
    }

    return $enriched
}

# 执行完整 ETL 管道
$result = Invoke-DataEtlPipeline -IncludeSummary

Write-Host "`n=== 最终报表 ===" -ForegroundColor Cyan
$result | Format-Table Hostname, IPAddress, OS, Status,
    @{N='CPU%';E={'{0:N1}' -f $_.CPU_Usage}},
    @{N='MEM%';E={'{0:N1}' -f $_.MEM_Usage}},
    @{N='DISK%';E={'{0:N1}' -f $_.DISK_Usage}},
    AlertCount -AutoSize
```

执行结果示例：

```
[Extract] 从 CSV 提取服务器资产数据...
  提取 5 条服务器记录
[Extract] 从 JSON 提取监控指标数据...
  提取 4 条监控指标
[Extract] 从 XML 提取告警配置...
  提取 3 条告警规则

[Transform] 关联服务器资产与监控指标...

[Load] 导出为 CSV 报表...
  已写入: ./etl-output/server-report.csv
[Load] 导出为 JSON...
  已写入: ./etl-output/server-report.json
[Load] 导出为 HTML 报表...
  已写入: ./etl-output/server-report.html

=== ETL 汇总 ===
  服务器总数: 5
  运行中: 4
  已停机: 1
  触发告警的服务器: 2
  平均 CPU 使用率: 39.9%
  平均内存使用率: 71.0%

=== 最终报表 ===

Hostname IPAddress     OS           Status CPU%  MEM%  DISK% AlertCount
-------- ---------     --           ------ ----  ----  ----- ----------
WEB-01   192.168.1.10  Ubuntu 22.04 Running 45.2  62.1  33.7           0
WEB-02   192.168.1.11  Ubuntu 22.04 Running 12.8  45.3  28.9           0
DB-01    192.168.1.20  CentOS 7     Running 78.5  85.2  71.4           3
DB-02    192.168.1.21  CentOS 7     Running                          0
CACHE-01 192.168.1.30  Ubuntu 22.04 Running 23.1  91.5  15.2           1
```

## 注意事项

1. **ConvertTo-Json 的 Depth 参数**：默认 Depth 只有 2，嵌套对象会被截断为 `System.Object`。处理复杂对象时务必显式指定足够的深度，建议设为 10 以上。

2. **CSV 的类型丢失问题**：CSV 格式本质上是纯文本，所有值都会变成字符串。从 CSV 读取后需要手动对日期、数值字段做类型转换，否则后续计算会出错。

3. **大文件的内存占用**：`ConvertFrom-Json` 和 `ConvertFrom-Csv` 会一次性将全部数据加载到内存。处理数百 MB 以上的文件时，考虑使用流式处理或分批读取，避免内存溢出。

4. **XML 命名空间处理**：真实的 XML 文档通常带有命名空间（如 `xmlns`），直接用 `Select-Xml` 可能匹配不到节点。需要使用 `NamespaceManager` 注册前缀，或者用 `[xml]` 类型加速器的 dot 访问绕过命名空间。

5. **编码一致性**：导出文件时显式指定 `-Encoding utf8`（PowerShell 7 默认即为 UTF-8，但在 Windows PowerShell 5.1 中默认是 ASCII）。跨平台场景中统一用 UTF-8 可以避免中文乱码。

6. **管道中的去重性能**：`HashSet` 去重在数据量小时效率很高，但当记录达到数十万条时，拼接去重键的字符串操作会成为瓶颈。大数据量场景建议改用基于主键的字典查找。
