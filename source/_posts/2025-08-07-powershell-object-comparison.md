---
layout: post
date: 2025-08-07 08:00:00
title: "PowerShell 技能连载 - 对象比较与差异检测"
description: PowerTip of the Day - Object Comparison and Difference Detection in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- comparison
- diff
- objects
---

_适用于 PowerShell 5.1 及以上版本_

配置漂移检测、变更审计、版本对比——运维中经常需要比较两份数据的差异。PowerShell 的 `Compare-Object` 可以比较两个对象集合，`ConvertTo-Html` 可以生成可视化的对比报告。但很多用户只会用 `Compare-Object` 做简单的字符串比较，不了解如何对比复杂对象属性、生成差异报告、检测配置漂移。

本文将讲解 PowerShell 中的对象比较技巧和实用的差异检测方案。

## Compare-Object 基础

```powershell
# 简单数组比较
$oldServers = @("SRV01", "SRV02", "SRV03", "SRV04")
$newServers = @("SRV02", "SRV03", "SRV05", "SRV06")

$diff = Compare-Object $oldServers $newServers
$diff | Format-Table -AutoSize

# 解读结果
# <= 表示只在左侧（oldServers）
# => 表示只在右侧（newServers）
$added = $diff | Where-Object { $_.SideIndicator -eq '=>' }
$removed = $diff | Where-Object { $_.SideIndicator -eq '<=' }

Write-Host "新增服务器：$($added.InputObject -join ', ')" -ForegroundColor Green
Write-Host "移除服务器：$($removed.InputObject -join ', ')" -ForegroundColor Red

# 使用 -Property 比较对象属性
$oldConfig = @(
    [PSCustomObject]@{ Server = "SRV01"; IP = "10.0.1.1"; Role = "Web" }
    [PSCustomObject]@{ Server = "SRV02"; IP = "10.0.1.2"; Role = "DB" }
    [PSCustomObject]@{ Server = "SRV03"; IP = "10.0.1.3"; Role = "Web" }
)

$newConfig = @(
    [PSCustomObject]@{ Server = "SRV01"; IP = "10.0.1.1"; Role = "Web" }
    [PSCustomObject]@{ Server = "SRV02"; IP = "10.0.2.2"; Role = "DB" }
    [PSCustomObject]@{ Server = "SRV04"; IP = "10.0.1.4"; Role = "App" }
)

# 按 Server 属性比较
Compare-Object $oldConfig $newConfig -Property Server -IncludeEqual |
    Format-Table -AutoSize
```

执行结果示例：

```
InputObject SideIndicator
----------- -------------
SRV01       <=
SRV04       <=
SRV05       =>
SRV06       =>
新增服务器：SRV05, SRV06
移除服务器：SRV01, SRV04

Server SideIndicator
------ -------------
SRV01  ==
SRV02  ==
SRV03  <=
SRV04  =>
```

## 属性级差异检测

```powershell
# 深度属性比较
function Compare-ObjectProperties {
    param(
        [Parameter(Mandatory)]
        $ReferenceObject,

        [Parameter(Mandatory)]
        $DifferenceObject,

        [string[]]$Properties,

        [string]$KeyProperty
    )

    $diffs = @()

    if ($KeyProperty) {
        # 按键属性匹配后比较
        foreach ($prop in $Properties) {
            $refVal = $ReferenceObject.$prop
            $diffVal = $DifferenceObject.$prop

            if ($refVal -ne $diffVal) {
                $diffs += [PSCustomObject]@{
                    Property    = $prop
                    OldValue    = $refVal
                    NewValue    = $diffVal
                    Key         = "$KeyProperty=$($ReferenceObject.$KeyProperty)"
                    IsDifferent = $true
                }
            }
        }
    }

    return $diffs
}

# 比较服务器配置变更
$oldServers = @(
    [PSCustomObject]@{ Name = "SRV01"; IP = "10.0.1.1"; OS = "2022"; CPU = 8 }
    [PSCustomObject]@{ Name = "SRV02"; IP = "10.0.1.2"; OS = "2019"; CPU = 16 }
)

$newServers = @(
    [PSCustomObject]@{ Name = "SRV01"; IP = "10.0.1.1"; OS = "2022"; CPU = 16 }
    [PSCustomObject]@{ Name = "SRV02"; IP = "10.0.2.2"; OS = "2022"; CPU = 16 }
)

Write-Host "服务器配置差异：" -ForegroundColor Cyan
foreach ($old in $oldServers) {
    $new = $newServers | Where-Object { $_.Name -eq $old.Name }
    if ($new) {
        $diffs = Compare-ObjectProperties -ReferenceObject $old -DifferenceObject $new `
            -Properties @("IP", "OS", "CPU") -KeyProperty "Name"

        if ($diffs) {
            Write-Host "`n  $($old.Name) 变更：" -ForegroundColor Yellow
            $diffs | Format-Table Property, OldValue, NewValue -AutoSize | Out-String | Write-Host
        }
    }
}
```

执行结果示例：

```
服务器配置差异：

  SRV01 变更：
  Property OldValue NewValue
  -------- -------- --------
  CPU      8        16

  SRV02 变更：
  Property OldValue NewValue
  -------- -------- --------
  IP       10.0.1.2 10.0.2.2
  OS       2019     2022
```

## 配置漂移检测

```powershell
# 检测配置文件漂移
function Test-ConfigDrift {
    param(
        [Parameter(Mandatory)]
        [string]$BaselinePath,

        [Parameter(Mandatory)]
        [string]$CurrentPath,

        [string]$KeyProperty = "Name"
    )

    $baseline = Get-Content $BaselinePath -Raw | ConvertFrom-Json
    $current = Get-Content $CurrentPath -Raw | ConvertFrom-Json

    $drifts = @()

    # 检查基准中的每个条目
    foreach ($baseItem in $baseline) {
        $key = $baseItem.$KeyProperty
        $currentItem = $current | Where-Object { $_.$KeyProperty -eq $key }

        if (-not $currentItem) {
            $drifts += [PSCustomObject]@{
                Key      = $key
                Type     = "MISSING"
                Property = "ALL"
                Expected = "存在"
                Actual   = "不存在"
            }
            continue
        }

        # 逐属性比较
        foreach ($prop in $baseItem.PSObject.Properties.Name) {
            if ($baseItem.$prop -ne $currentItem.$prop) {
                $drifts += [PSCustomObject]@{
                    Key      = $key
                    Type     = "CHANGED"
                    Property = $prop
                    Expected = $baseItem.$prop
                    Actual   = $currentItem.$prop
                }
            }
        }
    }

    # 检查新增条目
    foreach ($curItem in $current) {
        $key = $curItem.$KeyProperty
        $baseItem = $baseline | Where-Object { $_.$KeyProperty -eq $key }
        if (-not $baseItem) {
            $drifts += [PSCustomObject]@{
                Key      = $key
                Type     = "ADDED"
                Property = "ALL"
                Expected = "不存在"
                Actual   = "存在"
            }
        }
    }

    if ($drifts) {
        Write-Host "检测到 $($drifts.Count) 处配置漂移：" -ForegroundColor Red
        $drifts | Format-Table -AutoSize
    } else {
        Write-Host "配置与基准一致" -ForegroundColor Green
    }

    return $drifts
}

# 创建基准和当前配置
$baselineJson = @'
[
    {"Name":"SRV01","IP":"10.0.1.1","Role":"Web","Status":"Active"},
    {"Name":"SRV02","IP":"10.0.1.2","Role":"DB","Status":"Active"},
    {"Name":"SRV03","IP":"10.0.1.3","Role":"App","Status":"Active"}
]
'@

$currentJson = @'
[
    {"Name":"SRV01","IP":"10.0.1.1","Role":"Web","Status":"Maintenance"},
    {"Name":"SRV02","IP":"10.0.2.2","Role":"DB","Status":"Active"},
    {"Name":"SRV04","IP":"10.0.1.4","Role":"Web","Status":"Active"}
]
'@

$baselineJson | Set-Content "C:\Config\baseline.json" -Encoding UTF8
$currentJson | Set-Content "C:\Config\current.json" -Encoding UTF8

Test-ConfigDrift -BaselinePath "C:\Config\baseline.json" -CurrentPath "C:\Config\current.json" -KeyProperty "Name"
```

执行结果示例：

```
检测到 4 处配置漂移：
Key   Type     Property Expected Actual
---   ----     -------- -------- ------
SRV01 CHANGED Status   Active   Maintenance
SRV02 CHANGED IP       10.0.1.2 10.0.2.2
SRV03 MISSING ALL      存在     不存在
SRV04 ADDED   ALL      不存在   存在
```

## 差异报告生成

```powershell
function New-DiffReport {
    param(
        [Parameter(Mandatory)]
        [object[]]$Differences,

        [string]$Title = "配置差异报告",

        [string]$OutputPath = "C:\Reports\diff-report.html"
    )

    $css = @"
<style>
body{font-family:'Segoe UI',sans-serif;margin:20px;background:#f5f6fa}
h1{color:#2d3436;border-bottom:2px solid #0984e3}
table{width:100%;border-collapse:collapse;margin:10px 0}
th{background:#0984e3;color:white;padding:10px;text-align:left}
td{padding:8px 10px;border-bottom:1px solid #dfe6e9}
.CHANGED{background:#fff3cd}
.ADDED{background:#d4edda}
.MISSING{background:#f8d7da}
.summary{display:flex;gap:15px;margin:15px 0}
.card{background:white;border-radius:8px;padding:15px;box-shadow:0 2px 4px rgba(0,0,0,0.1)}
.card .value{font-size:24px;font-weight:bold}
</style>
"@

    $changed = ($Differences | Where-Object { $_.Type -eq "CHANGED" }).Count
    $added = ($Differences | Where-Object { $_.Type -eq "ADDED" }).Count
    $missing = ($Differences | Where-Object { $_.Type -eq "MISSING" }).Count

    $rows = foreach ($diff in $Differences) {
        "<tr class=`"$($diff.Type)`"><td>$($diff.Key)</td><td>$($diff.Type)</td><td>$($diff.Property)</td><td>$($diff.Expected)</td><td>$($diff.Actual)</td></tr>"
    }

    $html = @"
<!DOCTYPE html><html><head><meta charset="UTF-8"><title>$Title</title>$css</head>
<body><h1>$Title</h1><p>生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
<div class="summary">
<div class="card"><div class="value" style="color:#f39c12">$changed</div><div>变更</div></div>
<div class="card"><div class="value" style="color:#27ae60">$added</div><div>新增</div></div>
<div class="card"><div class="value" style="color:#e74c3c">$missing</div><div>缺失</div></div>
</div>
<table><tr><th>键</th><th>类型</th><th>属性</th><th>期望值</th><th>实际值</th></tr>
$rows
</table></body></html>
"@

    $html | Set-Content $OutputPath -Encoding UTF8
    Write-Host "差异报告已生成：$OutputPath" -ForegroundColor Green
}

# 使用之前的差异结果生成报告
$drifts = Test-ConfigDrift -BaselinePath "C:\Config\baseline.json" -CurrentPath "C:\Config\current.json" -KeyProperty "Name"
New-DiffReport -Differences $drifts -Title "服务器配置漂移报告"
```

执行结果示例：

```
检测到 4 处配置漂移：
差异报告已生成：C:\Reports\diff-report.html
```

## 注意事项

1. **Compare-Object 限制**：`Compare-Object` 默认只比较字符串表示，复杂对象需要指定 `-Property`
2. **顺序无关**：`Compare-Object` 是无序比较，不关心元素顺序
3. **IncludeEqual**：使用 `-IncludeEqual` 显示相同的项，适合生成完整的对比报告
4. **PassThru**：`-PassThru` 参数返回原始对象而非比较结果，方便后续处理
5. **Culture 影响**：字符串比较受当前文化设置影响，技术数据建议使用 `-CultureInvariant`
6. **大数据量**：比较大量对象时 `Compare-Object` 性能较差，考虑使用哈希表查找
