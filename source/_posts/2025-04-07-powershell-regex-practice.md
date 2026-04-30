---
layout: post
date: 2025-04-07 08:00:00
title: "PowerShell 技能连载 - 正则表达式实战"
description: PowerTip of the Day - Regex Practice
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- regex
- text-processing
---

_适用于 PowerShell 5.1 及以上版本_

在日常运维和数据处理中，我们经常需要从大量文本中提取特定信息、验证输入格式或批量替换内容。正则表达式（Regular Expression）是处理这类任务的利器。PowerShell 基于 .NET 的正则引擎，提供了丰富且强大的文本处理能力。

许多管理员对正则表达式望而生畏，觉得语法晦涩难懂。但实际上，掌握少数几个核心模式就能解决大部分日常工作需求。本文将从基础匹配开始，逐步深入到捕获组、替换操作和常用验证模式。

## 基础正则匹配

PowerShell 中最常用的正则操作符是 `-match`，它会对字符串进行正则匹配，匹配成功返回 `$true`，并将匹配结果存入 `$Matches` 自动变量。

```powershell
# 简单匹配：检查字符串是否包含数字
$text = "订单编号：A20250407-0032"
if ($text -match '\d+') {
    Write-Host "找到数字：$($Matches[0])"
}
```

```
找到数字：20250407
```

`-match` 操作符默认不区分大小写，如果需要区分大小写，请使用 `-cmatch`。对应的否定操作符是 `-notmatch`（不区分大小写）和 `-cnotmatch`（区分大小写）。

## 捕获组与提取

正则表达式中使用圆括号 `()` 来定义捕获组。每个捕获组会按左括号出现的顺序编号，存入 `$Matches` 哈希表中。

```powershell
# 使用捕获组提取结构化信息
$logLine = '192.168.1.100 - - [07/Apr/2025:10:30:45 +0800] "GET /api/users HTTP/1.1" 200 1234'
$pattern = '^(\d+\.\d+\.\d+\.\d+).*\[(.+?)\].*?"(\w+)\s+(\S+)\s'.*

if ($logLine -match $pattern) {
    Write-Host "客户端 IP：$($Matches[1])"
    Write-Host "请求时间：$($Matches[2])"
    Write-Host "请求方法：$($Matches[3])"
    Write-Host "请求路径：$($Matches[4])"
}
```

```
客户端 IP：192.168.1.100
请求时间：07/Apr/2025:10:30:45 +0800
请求方法：GET
请求路径：/api/users
```

还可以使用命名捕获组 `(?<name>...)` 来让正则更具可读性。

```powershell
# 命名捕获组
$email = "请联系 admin@vichamp.com 获取支持"
$pattern = '(?<user>[\w.+-]+)@(?<domain>[\w-]+\.[\w.]+)'

if ($email -match $pattern) {
    Write-Host "用户名：$($Matches['user'])"
    Write-Host "域名：$($Matches['domain'])"
}
```

```
用户名：admin
域名：vichamp.com
```

## 正则替换

`-replace` 操作符使用正则进行文本替换。基本语法为 `<输入> -replace <模式>, <替换文本>`。在替换文本中可以使用 `$1`、`$2` 等引用捕获组。

```powershell
# 脱敏处理：隐藏手机号中间四位
$contact = "用户手机号为 13812345678，请尽快联系"
$masked = $contact -replace '(\d{3})\d{4}(\d{4})', '$1****$2'
Write-Host $masked
```

```
用户手机号为 138****5678，请尽快联系
```

对于更复杂的替换逻辑，可以使用 `[regex]::Replace()` 方法并传入脚本块。

```powershell
# 使用脚本块进行动态替换：将日期格式从 YYYYMMDD 转为 YYYY-MM-DD
$text = "日志文件 log_20250407.txt 和 backup_20250406.zip"
$result = [regex]::Replace($text, '(\d{4})(\d{2})(\d{2})', {
    param($m)
    "$($m.Groups[1].Value)-$($m.Groups[2].Value)-$($m.Groups[3].Value)"
})
Write-Host $result
```

```
日志文件 log_2025-04-07.txt 和 backup_2025-04-06.zip
```

## 常用验证模式

下面列出几个运维中常用的正则验证模式。

### 验证 IP 地址

```powershell
# IPv4 地址验证
function Test-IPv4Address {
    param([string]$Address)
    $pattern = '^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$'
    return $Address -match $pattern
}

# 测试多个地址
@("192.168.1.1", "10.0.0.999", "172.16.0.0", "256.1.1.1") | ForEach-Object {
    $valid = if (Test-IPv4Address $_) { "有效" } else { "无效" }
    Write-Host "$_ -> $valid"
}
```

```
192.168.1.1 -> 有效
10.0.0.999 -> 无效
172.16.0.0 -> 有效
256.1.1.1 -> 无效
```

### 验证邮箱地址

```powershell
# 邮箱地址验证（常用简化版）
function Test-EmailAddress {
    param([string]$Email)
    $pattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return $Email -match $pattern
}

@("admin@vichamp.com", "user.name+tag@example.co.uk", "invalid-email", "@no-user.com") | ForEach-Object {
    $valid = if (Test-EmailAddress $_) { "有效" } else { "无效" }
    Write-Host "$_ -> $valid"
}
```

```
admin@vichamp.com -> 有效
user.name+tag@example.co.uk -> 有效
invalid-email -> 无效
@no-user.com -> 无效
```

### 验证日期格式

```powershell
# 验证 YYYY-MM-DD 格式的日期
function Test-DateFormat {
    param([string]$DateString)
    $pattern = '^(?<year>\d{4})-(?<month>0[1-9]|1[0-2])-(?<day>0[1-9]|[12]\d|3[01])$'
    if ($DateString -match $pattern) {
        # 进一步验证日期合法性
        try {
            [datetime]::new([int]$Matches['year'], [int]$Matches['month'], [int]$Matches['day']) | Out-Null
            return $true
        } catch {
            return $false
        }
    }
    return $false
}

@("2025-04-07", "2025-13-01", "2025-02-30", "2025-06-15") | ForEach-Object {
    $valid = if (Test-DateFormat $_) { "有效" } else { "无效" }
    Write-Host "$_ -> $valid"
}
```

```
2025-04-07 -> 有效
2025-13-01 -> 无效
2025-02-30 -> 无效
2025-06-15 -> 有效
```

## 批量提取文本中的信息

结合 `-match` 和管道操作，可以高效地从多个字符串中批量提取信息。

```powershell
# 从服务器日志中批量提取错误信息
$logs = @(
    "[ERROR] 2025-04-07 10:15:23 - 连接超时，目标 host-01:443",
    "[INFO] 2025-04-07 10:15:24 - 重试连接",
    "[ERROR] 2025-04-07 10:16:01 - 认证失败，用户 testuser",
    "[WARN] 2025-04-07 10:17:00 - 磁盘空间不足",
    "[ERROR] 2025-04-07 10:18:12 - 服务崩溃，PID=9527"
)

$errorPattern = '^\[ERROR\]\s+(?<time>\S+\s+\S+)\s+-\s+(?<message>.+)$'

$logs | Where-Object { $_ -match '^\[ERROR\]' } | ForEach-Object {
    if ($_ -match $errorPattern) {
        [PSCustomObject]@{
            时间   = $Matches['time']
            消息   = $Matches['message']
        }
    }
} | Format-Table -AutoSize
```

```
时间                消息
----                ----
2025-04-07 10:15:23 连接超时，目标 host-01:443
2025-04-07 10:16:01 认证失败，用户 testuser
2025-04-07 10:18:12 服务崩溃，PID=9527
```

## 使用 Select-String 进行文件搜索

`Select-String` cmdlet 可以在文件中搜索正则匹配，相当于 Linux 下的 `grep`。

```powershell
# 在所有日志文件中搜索今天的错误
$today = (Get-Date).ToString('yyyy-MM-dd')
$results = Get-ChildItem -Path "C:\Logs" -Filter "*.log" |
    Select-String -Pattern "\[ERROR\].*$today" |
    Select-Object -Property FileName, LineNumber, Line

$results | Format-Table -AutoSize
```

## 注意事项

- PowerShell 的 `-match` 操作符作用于标量时，匹配结果存入 `$Matches`；作用于集合时，返回所有匹配的元素，但 `$Matches` 只保留最后一次匹配的结果
- 正则中的特殊字符（如 `.`、`*`、`+`、`?`、`(`、`)`、`[`、`]`）需要用反斜杠 `\` 转义
- 对于复杂的正则表达式，建议使用命名捕获组来提高可读性
- 如果只需要简单的通配符匹配，使用 `-like` 操作符比正则更直观
- 处理大量文本时，预编译正则表达式（`[regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)`）可以提升性能
