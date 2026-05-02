---
layout: post
date: 2025-04-18 08:00:00
updated: 2025-04-18 08:00:00
title: "PowerShell 技能连载 - 哈希表与 PSCustomObject 深度解析"
description: PowerTip of the Day - Deep Dive into Hashtable and PSCustomObject
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- hashtable
- object
- data-structure
---
_适用于 PowerShell 7.0 及以上版本_

在 PowerShell 中，几乎所有数据都以对象的形式流转。哈希表（Hashtable）和 PSCustomObject 是两种最常用的结构化数据容器，它们贯穿于配置管理、API 调用、数据转换、管道处理等几乎所有场景。理解它们的异同和最佳使用时机，是写出高效、可维护脚本的关键。

本文将从基础操作入手，逐步深入到两者的选择策略、嵌套结构处理和实战数据转换，帮助你全面掌握这两种核心数据结构。

<!-- more -->

## Hashtable 基础操作

哈希表是 PowerShell 中最灵活的键值对容器，使用 `@{}` 语法创建。它支持动态添加和删除键值对，查找速度接近 O(1)，非常适合用作查找表、配置字典或分组聚合。

```powershell
# 创建哈希表
$config = @{
    Server   = "db01.vichamp.com"
    Port     = 5432
    Database = "production"
    Timeout  = 30
    Retries  = 3
}

# 读取值
Write-Host "服务器: $($config.Server)"
Write-Host "端口: $($config['Port'])"

# 添加和修改键值对
$config["MaxConnections"] = 100
$config.Timeout = 60

# 删除键值对
$config.Remove("Retries")

# 遍历所有键值对
foreach ($key in $config.Keys) {
    Write-Host "  $key = $($config[$key])"
}

# 检查键是否存在
$hasPort = $config.ContainsKey("Port")
Write-Host "包含 Port 键: $hasPort"
```

执行结果示例：

```text
服务器: db01.vichamp.com
端口: 5432
包含 Port 键: True
  Server = db01.vichamp.com
  Port = 5432
  Database = production
  Timeout = 60
  MaxConnections = 100
包含 Port 键: True
```

## PSCustomObject 多种创建方式

PSCustomObject 是 PowerShell 专属的轻量级对象类型，相比 Hashtable，它拥有固定的属性名顺序，在管道中可直接使用 `Select-Object`、`Sort-Object`、`Format-Table` 等命令，输出格式也更加友好。PowerShell 提供了多种创建方式，各有适用场景。

```powershell
# 方式一：最简洁的字面量语法（推荐）
$person = [PSCustomObject]@{
    Name   = "张三"
    Age    = 32
    Email  = "zhangsan@vichamp.com"
    Role   = "DevOps Engineer"
}

# 方式二：先创建再添加属性
$server = [PSCustomObject]@{
    HostName = "web01"
    IP       = "10.0.1.100"
}
$server | Add-Member -NotePropertyName "Status" -NotePropertyValue "Running"
$server | Add-Member -NotePropertyName "Uptime" -NotePropertyValue "15d 3h"

# 方式三：New-Object 配合 Property 参数
$logEntry = New-Object -TypeName PSObject -Property @{
    Timestamp = Get-Date
    Level     = "INFO"
    Message   = "服务启动完成"
}

# 输出对比
Write-Host "--- Person ---"
$person | Format-Table
Write-Host "--- Server ---"
$server | Format-List
```

执行结果示例：

```text
--- Person ---

Name  Age Email                 Role
----  --- -----                 ----
张三   32 zhangsan@vichamp.com DevOps Engineer

--- Server ---

HostName : web01
IP       : 10.0.1.100
Status   : Running
Uptime   : 15d 3h
```

## Hashtable vs PSCustomObject 选择策略

很多初学者在 Hashtable 和 PSCustomObject 之间犹豫不决。核心原则很简单：需要字典语义（快速查找、动态键名）用 Hashtable，需要对象语义（固定属性、管道友好）用 PSCustomObject。下面的代码演示了两者在典型场景中的表现差异。

```powershell
# 场景一：动态键名查找 → 用 Hashtable
$httpStatusMap = @{
    200 = "OK"
    301 = "Moved Permanently"
    404 = "Not Found"
    500 = "Internal Server Error"
}

$code = 404
Write-Host "状态码 $code 的含义: $($httpStatusMap[$code])"

# 场景二：结构化数据输出 → 用 PSCustomObject
function Get-ServerInfo {
    param([string[]]$Names)

    foreach ($name in $Names) {
        [PSCustomObject]@{
            Name      = $name
            Status    = if (Test-Connection -TargetName $name -Count 1 -Quiet) { "Up" } else { "Down" }
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

# 场景三：Hashtable 转 PSCustomObject
$rawUser = @{
    login    = "victorwoo"
    name     = "Victor Wu"
    location = "Shanghai"
    repos    = 42
}

# 通过强制类型转换，一次性转为有序对象
$user = [PSCustomObject]$rawUser
$user | Format-Table
```

执行结果示例：

```text
状态码 404 的含义: Not Found

login    name       location repos
----    ----        -------- -----
victorwoo Victor Wu  Shanghai    42
```

## 嵌套结构处理

实际工作中，配置文件和 API 返回的数据往往是多层嵌套结构。PowerShell 处理嵌套的技巧在于逐层访问，合理混合使用 Hashtable（内部字典）和 PSCustomObject（外层对象），让数据既有良好的可读性，又方便在管道中操作。

```powershell
# 模拟一个多环境部署配置
$deployConfig = [PSCustomObject]@{
    Application = "BlogEngine"
    Version     = "3.2.1"
    Environments = @{
        Dev  = @{
            Server    = "dev-blog.vichamp.com"
            Port      = 8080
            Debug     = $true
            Instances = 1
        }
        Staging = @{
            Server    = "staging-blog.vichamp.com"
            Port      = 443
            Debug     = $false
            Instances = 2
        }
        Production = @{
            Server    = "blog.vichamp.com"
            Port      = 443
            Debug     = $false
            Instances = 4
            CDN       = "cloudflare"
        }
    }
    Features = @("Search", "Comments", "Analytics")
}

# 遍历所有环境配置
foreach ($envName in $deployConfig.Environments.Keys) {
    $envConfig = $deployConfig.Environments[$envName]
    [PSCustomObject]@{
        Environment = $envName
        Server      = $envConfig.Server
        Port        = $envConfig.Port
        Instances   = $envConfig.Instances
        Debug       = $envConfig.Debug
    } | Format-Table -AutoSize
}
```

执行结果示例：

```text
Environment Server                   Port Instances Debug
----------- ------                   ---- --------- -----
Dev         dev-blog.vichamp.com     8080         1  True

Environment Server                      Port Instances Debug
----------- ------                      ---- --------- -----
Staging     staging-blog.vichamp.com     443         2 False

Environment Server              Port Instances Debug
----------- ------              ---- --------- -----
Production  blog.vichamp.com     443         4 False
```

## 实战：API 数据转换

在日常运维和自动化脚本中，最常见的需求是将 API 返回的原始数据（通常是 Hashtable 或 JSON）转换为结构化的 PSCustomObject，以便筛选、排序和导出。以下示例模拟了一个服务器监控场景，展示完整的数据流转过程。

```powershell
# 模拟 API 返回的原始数据（JSON 反序列化后为 Hashtable 数组）
$rawApiResponse = @(
    @{
        Host     = "web01"
        Cpu      = 78.5
        Memory   = 65.2
        DiskFree = "120GB"
        Status   = "Healthy"
        Tags     = @("frontend", "nginx")
    }
    @{
        Host     = "web02"
        Cpu      = 92.1
        Memory   = 88.7
        DiskFree = "8GB"
        Status   = "Warning"
        Tags     = @("frontend", "nginx", "high-load")
    }
    @{
        Host     = "db01"
        Cpu      = 45.3
        Memory   = 72.1
        DiskFree = "500GB"
        Status   = "Healthy"
        Tags     = @("database", "postgresql")
    }
)

# 转换为 PSCustomObject 并添加计算属性
$serverMetrics = $rawApiResponse | ForEach-Object {
    [PSCustomObject]@{
        Host       = $_.Host
        CpuPercent = [math]::Round($_.Cpu, 1)
        MemPercent = [math]::Round($_.Memory, 1)
        DiskFree   = $_.DiskFree
        Status     = $_.Status
        TagList    = $_.Tags -join ", "
        AlertLevel = if ($_.Cpu -gt 90 -or $_.Memory -gt 85) { "Critical" }
                     elseif ($_.Cpu -gt 75 -or $_.Memory -gt 70) { "Warning" }
                     else { "Normal" }
        CheckedAt  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# 筛选需要关注的服务器
$alertServers = $serverMetrics |
    Where-Object { $_.AlertLevel -ne "Normal" } |
    Sort-Object -Property CpuPercent -Descending

Write-Host "=== 服务器监控总览 ==="
$serverMetrics | Format-Table -AutoSize

Write-Host "`n=== 需要关注的服务器 ==="
$alertServers | Format-Table Host, CpuPercent, MemPercent, AlertLevel -AutoSize
```

执行结果示例：

```text
=== 服务器监控总览 ===

Host  CpuPercent MemPercent DiskFree Status  TagList                   AlertLevel CheckedAt
----  ---------- ---------- -------- ------  -------                   ---------- ---------
web01       78.5       65.2   120GB  Healthy frontend, nginx             Warning 2025-04-18 08:30:00
web02       92.1       88.7     8GB  Warning frontend, nginx, high-load  Critical 2025-04-18 08:30:00
db01        45.3       72.1   500GB  Healthy database, postgresql        Normal 2025-04-18 08:30:00

=== 需要关注的服务器 ===

Host  CpuPercent MemPercent AlertLevel
----  ---------- ---------- ----------
web02       92.1       88.7 Critical
web01       78.5       65.2 Warning
```

## 小结

Hashtable 和 PSCustomObject 各有所长：Hashtable 适合动态键值查找、分组聚合和配置字典等场景；PSCustomObject 适合结构化数据输出、管道操作和最终展示。实际项目中两者经常配合使用——用 Hashtable 构建内部数据结构，最终转换为 PSCustomObject 输出。记住这个原则：**构建用 Hashtable，展示用 PSCustomObject**。
