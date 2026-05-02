---
layout: post
date: 2025-07-02 08:00:00
updated: 2025-07-02 08:00:00
title: "PowerShell 技能连载 - 哈希表与字典深入"
description: PowerTip of the Day - Hashtable and Dictionary Deep Dive in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- hashtable
- dictionary
- data-structure
---

_适用于 PowerShell 5.1 及以上版本_

哈希表（Hashtable）是 PowerShell 中使用频率最高的数据结构之一——从 `ConvertFrom-Json` 的输出到 `Invoke-Command` 的参数，从配置管理到缓存系统，哈希表无处不在。然而，很多用户只会基本的键值操作，不了解有序字典、大小写敏感性、嵌套结构、线程安全字典等高级特性。深入理解这些特性，可以写出更高效、更优雅的代码。

本文将系统讲解 PowerShell 中哈希表和相关字典类型的用法与最佳实践。

<!-- more -->

## 基础操作与技巧

```powershell
# 创建哈希表
$config = @{
    Server   = "prod-db01"
    Port     = 5432
    Database = "MyApp"
    Timeout  = 30
    ReadOnly = $false
}

# 访问值
Write-Host "服务器：$($config.Server)"
Write-Host "端口：$($config['Port'])"

# 动态键名访问
$key = "Database"
Write-Host "数据库：$($config[$key])"

# 添加和删除
$config["MaxPoolSize"] = 100
$config.Remove("ReadOnly")

# 检查键是否存在
if ($config.ContainsKey("Timeout")) {
    Write-Host "超时设置：$($config.Timeout) 秒"
}

# 遍历
$config.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}

# 克隆（浅拷贝）
$config2 = $config.Clone()
$config2["Port"] = 3306
Write-Host "原端口：$($config.Port)，克隆端口：$($config2.Port)"

# 合并哈希表
$defaults = @{ Timeout = 30; Retry = 3; Verbose = $false }
$override = @{ Timeout = 60; Server = "dev-db01" }

$merged = @{ }
foreach ($key in $defaults.Keys) { $merged[$key] = $defaults[$key] }
foreach ($key in $override.Keys) { $merged[$key] = $override[$key] }

Write-Host "合并后 Timeout：$($merged.Timeout)，Server：$($merged.Server)"
```

执行结果示例：

```
服务器：prod-db01
端口：5432
数据库：MyApp
超时设置：30 秒
  Server = prod-db01
  Port = 5432
  Database = MyApp
  Timeout = 30
  MaxPoolSize = 100
原端口：5432，克隆端口：3306
合并后 Timeout：60，Server：dev-db01
```

## 有序字典

普通哈希表不保证键的顺序。如果需要保持插入顺序，使用 `[ordered]`：

```powershell
# 普通哈希表——顺序不确定
$unordered = @{ Z = 1; A = 2; M = 3 }
Write-Host "普通哈希表键序：$($unordered.Keys -join ', ')"

# 有序字典——保持插入顺序
$ordered = [ordered]@{ First = "Step1"; Second = "Step2"; Third = "Step3" }
Write-Host "有序字典键序：$($ordered.Keys -join ', ')"

# 有序字典适合构建配置步骤
$deploySteps = [ordered]@{
    "1-备份"   = { Write-Host "  备份数据库..." }
    "2-停止"   = { Write-Host "  停止服务..." }
    "3-更新"   = { Write-Host "  更新文件..." }
    "4-迁移"   = { Write-Host "  运行迁移..." }
    "5-启动"   = { Write-Host "  启动服务..." }
    "6-验证"   = { Write-Host "  健康检查..." }
}

Write-Host "执行部署步骤：" -ForegroundColor Cyan
foreach ($step in $deploySteps.GetEnumerator()) {
    Write-Host "[$($step.Key)]" -ForegroundColor Yellow -NoNewline
    & $step.Value
}

# 转换为 PSCustomObject（有序）
$obj = [PSCustomObject]$ordered
$obj | Format-Table
```

执行结果示例：

```
普通哈希表键序：Z, A, M
有序字典键序：First, Second, Third
执行部署步骤：
[1-备份]   备份数据库...
[2-停止]   停止服务...
[3-更新]   更新文件...
[4-迁移]   运行迁移...
[5-启动]   启动服务...
[6-验证]   健康检查...
```

## 嵌套哈希表

```powershell
# 构建多层嵌套配置
$envConfig = @{
    dev = @{
        Db   = @{ Server = "dev-db"; Port = 5432 }
        Api  = @{ Url = "https://dev-api.example.com"; Key = "dev-key" }
        Log  = @{ Level = "Debug"; Path = "C:\Logs\dev" }
    }
    staging = @{
        Db   = @{ Server = "staging-db"; Port = 5432 }
        Api  = @{ Url = "https://staging-api.example.com"; Key = "staging-key" }
        Log  = @{ Level = "Info"; Path = "C:\Logs\staging" }
    }
    prod = @{
        Db   = @{ Server = "prod-db"; Port = 5432 }
        Api  = @{ Url = "https://api.example.com"; Key = $null }
        Log  = @{ Level = "Warning"; Path = "C:\Logs\prod" }
    }
}

# 安全访问嵌套值
function Get-NestedValue {
    param($Hashtable, [string[]]$Path)

    $current = $Hashtable
    foreach ($key in $Path) {
        if ($current -is [hashtable] -and $current.ContainsKey($key)) {
            $current = $current[$key]
        } else {
            return $null
        }
    }
    return $current
}

$dbServer = Get-NestedValue $envConfig "dev", "Db", "Server"
Write-Host "开发环境数据库：$dbServer"

# 深度合并哈希表
function Merge-HashtableDeep {
    param($Base, $Override)

    $result = @{}
    foreach ($key in $Base.Keys) { $result[$key] = $Base[$key] }

    foreach ($key in $Override.Keys) {
        if ($result[$key] -is [hashtable] -and $Override[$key] -is [hashtable]) {
            $result[$key] = Merge-HashtableDeep $result[$key] $Override[$key]
        } else {
            $result[$key] = $Override[$key]
        }
    }
    return $result
}

$customOverride = @{ prod = @{ Db = @{ Port = 5433 }; Log = @{ Level = "Error" } } }
$customConfig = Merge-HashtableDeep $envConfig $customOverride
Write-Host "自定义生产环境端口：$(Get-NestedValue $customConfig 'prod','Db','Port')"
Write-Host "自定义生产环境日志级别：$(Get-NestedValue $customConfig 'prod','Log','Level')"
```

执行结果示例：

```
开发环境数据库：dev-db
自定义生产环境端口：5433
自定义生产环境日志级别：Error
```

## 从对象和 JSON 转换

```powershell
# 对象转哈希表
function ConvertTo-Hashtable {
    param(
        [Parameter(Mandatory)][object]$InputObject,
        [int]$Depth = 10
    )

    if ($Depth -le 0) { return $InputObject }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        return @($InputObject | ForEach-Object { ConvertTo-Hashtable $_ ($Depth - 1) })
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $hash = @{}
        $InputObject.PSObject.Properties | ForEach-Object {
            $hash[$_.Name] = ConvertTo-Hashtable $_.Value ($Depth - 1)
        }
        return $hash
    }

    return $InputObject
}

# JSON 转有序哈希表
$json = '{"name":"MyApp","version":"1.2.0","features":["auth","api","web"]}'
$obj = $json | ConvertFrom-Json
$hash = ConvertTo-Hashtable $obj
Write-Host "应用名：$($hash.name)，版本：$($hash.version)"
Write-Host "特性：$($hash.features -join ', ')"

# 哈希表过滤
$metrics = @{
    "CPU使用率" = 75.2
    "内存使用率" = 82.1
    "磁盘使用率" = 45.6
    "网络延迟" = 12.3
    "错误率" = 0.5
}

$alerts = $metrics.GetEnumerator() | Where-Object { $_.Value -gt 50 }
Write-Host "超过阈值的指标：" -ForegroundColor Yellow
$alerts | ForEach-Object { Write-Host "  $($_.Key)：$($_.Value)" -ForegroundColor Red }
```

执行结果示例：

```
应用名：MyApp，版本：1.2.0
特性：auth, api, web
超过阈值的指标：
  CPU使用率：75.2
  内存使用率：82.1
```

## 线程安全字典

在并发场景中使用 `ConcurrentDictionary`：

```powershell
# 创建线程安全字典
$results = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()

# 并行任务安全写入
$computers = @("SRV01", "SRV02", "SRV03", "SRV04", "SRV05")

$computers | ForEach-Object -Parallel {
    $dict = $using:results
    $computer = $_

    try {
        $ping = Test-Connection -ComputerName $computer -Count 1 -Quiet
        $os = if ($ping) {
            (Get-CimInstance Win32_OperatingSystem -ComputerName $computer -ErrorAction Stop).Caption
        } else {
            "不可达"
        }

        $dict.TryAdd($computer, @{
            Online  = $ping
            OS      = $os
            Checked = (Get-Date -Format 'HH:mm:ss')
        }) | Out-Null
    } catch {
        $dict.TryAdd($computer, @{ Online = $false; OS = "错误"; Error = $_.Exception.Message }) | Out-Null
    }
}

# 输出结果
$results.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $status = if ($_.Value.Online) { "在线" } else { "离线" }
    $color = if ($_.Value.Online) { "Green" } else { "Red" }
    Write-Host "$($_.Key): $status - $($_.Value.OS)" -ForegroundColor $color
}
```

执行结果示例：

```
SRV01: 在线 - Microsoft Windows Server 2022 Standard
SRV02: 在线 - Microsoft Windows Server 2022 Standard
SRV03: 离线 - 不可达
SRV04: 在线 - Microsoft Windows Server 2019 Standard
SRV05: 在线 - Microsoft Windows Server 2022 Datacenter
```

## 注意事项

1. **键的大小写**：`[hashtable]` 默认大小写不敏感，`[Dictionary[string,object]]` 默认大小写敏感
2. **遍历时修改**：遍历 `GetEnumerator()` 时不能添加或删除键，应先收集要修改的键再操作
3. **浅拷贝陷阱**：`Clone()` 只复制第一层引用，嵌套对象仍共享。深度拷贝需要递归处理
4. **有序字典类型**：`[ordered]` 创建的是 `OrderedDictionary`，不是 `Hashtable`，两者方法略有不同
5. **性能**：大量数据查找用哈希表（O(1)），不要用数组遍历（O(n)）
6. **JSON 转换**：`ConvertFrom-Json` 在 PowerShell 7 中返回有序字典，在 5.1 中返回 PSCustomObject
