---
layout: post
date: 2025-06-10 08:00:00
title: "PowerShell 技能连载 - 正则表达式深度应用"
description: PowerTip of the Day - Regular Expressions Deep Dive in PowerShell
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
- regex
- regular-expression
- text-processing
---

_适用于 PowerShell 5.1 及以上版本_

正则表达式是文本处理的终极武器——从日志分析、数据提取到输入验证，几乎所有文本处理场景都离不开正则。PowerShell 基于 .NET 的正则引擎，支持完整的正则语法，包括命名捕获组、零宽断言、平衡组等高级特性。掌握正则表达式可以大幅减少文本处理代码量，将几十行的字符串操作压缩为一行模式匹配。

本文将深入讲解 PowerShell 中的正则表达式应用，包括常用模式、高级特性和性能优化。

## 基础模式匹配

PowerShell 中使用正则的主要方式有：`-match` 运算符、`-replace` 运算符和 `Select-String` 命令：

```powershell
# -match 运算符（自动填充 $Matches 变量）
$text = "用户 admin 于 2025-06-10 08:30:15 登录"
if ($text -match '用户 (\w+) 于 (\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})') {
    Write-Host "用户名：$($Matches[1])"
    Write-Host "日期：$($Matches[2])"
    Write-Host "时间：$($Matches[3])"
}

# -replace 运算符（替换匹配文本）
$phone = "手机号：13812345678"
$masked = $phone -replace '(\d{3})\d{4}(\d{4})', '$1****$2'
Write-Host "脱敏后：$masked"

# 批量数据清洗
$logs = @(
    "192.168.1.100 - - [10/Jun/2025:08:30:15 +0800] GET /api/users 200 1234"
    "10.0.0.55 - - [10/Jun/2025:08:30:22 +0800] POST /api/login 401 56"
    "172.16.0.10 - - [10/Jun/2025:08:31:01 +0800] GET /static/css 304 0"
)

$pattern = '^(\S+)\s.*\[(.+?)\]\s+(\w+)\s+(\S+)\s+(\d+)\s+(\d+)'
foreach ($line in $logs) {
    if ($line -match $pattern) {
        [PSCustomObject]@{
            IP       = $Matches[1]
            Time     = $Matches[2]
            Method   = $Matches[3]
            Path     = $Matches[4]
            Status   = $Matches[5]
            Size     = $Matches[6]
        }
    }
} | Format-Table -AutoSize
```

执行结果示例：

```
用户名：admin
日期：2025-06-10
时间：08:30:15

脱敏后：手机号：138****5678

IP            Time                      Method Path        Status Size
--            ----                      ------ ----        ------ ----
192.168.1.100 10/Jun/2025:08:30:15 +0800 GET    /api/users  200   1234
10.0.0.55     10/Jun/2025:08:30:22 +0800 POST   /api/login  401   56
172.16.0.10   10/Jun/2025:08:31:01 +0800 GET    /static/css 304   0
```

## 命名捕获组

命名捕获组使正则表达式更可读，通过名称而非数字引用匹配结果：

```powershell
# 使用命名捕获组 (?<name>pattern)
$logLine = '2025-06-10 08:30:15 ERROR [Database] Connection timeout after 30s'
$pattern = '(?<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(?<level>\w+)\s+\[(?<module>\w+)\]\s+(?<message>.+)'

if ($logLine -match $pattern) {
    Write-Host "时间：$($Matches.timestamp)"
    Write-Host "级别：$($Matches.level)"
    Write-Host "模块：$($Matches.module)"
    Write-Host "消息：$($Matches.message)"
}

# 使用 [regex] 类获得更强的控制
$regex = [regex]::new($pattern)
$match = $regex.Match($logLine)

if ($match.Success) {
    foreach ($name in @('timestamp', 'level', 'module', 'message')) {
        Write-Host "$name = $($match.Groups[$name].Value)"
    }
}

# 批量提取日志中的结构化数据
$structuredLogs = Get-Content "C:\Logs\app.log" -Tail 100 | ForEach-Object {
    if ($_ -match $pattern) {
        [PSCustomObject]@{
            Timestamp = $Matches.timestamp
            Level     = $Matches.level
            Module    = $Matches.module
            Message   = $Matches.message
        }
    }
}

$structuredLogs | Where-Object { $_.Level -eq 'ERROR' } |
    Format-Table -AutoSize
```

执行结果示例：

```
时间：2025-06-10 08:30:15
级别：ERROR
模块：Database
消息：Connection timeout after 30s

Timestamp            Level Module   Message
---------            ----- ------   -------
2025-06-10 08:30:15  ERROR Database Connection timeout after 30s
2025-06-10 08:35:22  ERROR API      Upstream timeout (504)
```

## 常用正则模式库

```powershell
# 常用验证模式
$patterns = @{
    IPv4        = '^(?:(?:25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d\d?)$'
    Email       = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    URL         = '^https?://[\w\-]+(\.[\w\-]+)+[/#?]?.*$'
    GUID        = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    Chinese     = '[一-鿿]+'
    Phone       = '^1[3-9]\d{9}$'
    DateISO     = '^\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])$'
    HexColor    = '^#(?:[0-9a-fA-F]{3}){1,2}$'
    SemVer      = '^\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?(?:\+[a-zA-Z0-9.]+)?$'
    MAC         = '^[0-9A-Fa-f]{2}(?::[0-9A-Fa-f]{2}){5}$'
}

# 验证函数
function Test-Pattern {
    param([string]$InputObject, [string]$Pattern)

    $regex = $patterns[$Pattern]
    if (-not $regex) {
        Write-Error "未知模式：$Pattern"
        return $false
    }
    return $InputObject -match $regex
}

# 测试
Test-Pattern -InputObject "192.168.1.100" -Pattern "IPv4"   # True
Test-Pattern -InputObject "not-an-ip" -Pattern "IPv4"       # False
Test-Pattern -InputObject "admin@contoso.com" -Pattern "Email" # True
Test-Pattern -InputObject "1.2.3" -Pattern "SemVer"          # True
```

执行结果示例：

```
True
False
True
True
```

## 高级替换技巧

```powershell
# 使用脚本块进行条件替换
$text = "订单号 ORD-2025-001，金额 ￥1234.56，客户 张三"
$result = $text -replace '(\d{4})', {
    param($match)
    $year = $match.Groups[1].Value
    if ([int]$year -gt 2020) { "[$year]" } else { $year }
}
Write-Host $result

# 使用 MatchEvaluator 进行复杂替换
$names = "john doe, JANE smith, bob wilson"
$capitalized = [regex]::Replace($names, '\b(\w)(\w+)', {
    param($m)
    $m.Groups[1].Value.ToUpper() + $m.Groups[2].Value.ToLower()
})
Write-Host $capitalized

# 模板变量替换
$template = "亲爱的 {{name}}，您的订单 {{orderId}} 已发货，预计 {{date}} 送达。"
$data = @{ name = '张三'; orderId = 'ORD-2025-001'; date = '2025-06-12' }

$result = [regex]::Replace($template, '\{\{(\w+)\}\}', {
    param($m)
    $key = $m.Groups[1].Value
    $data[$key] ?? "{{$key}}"
})
Write-Host $result
```

执行结果示例：

```
订单号 ORD-[2025]-001，金额 ￥1234.56，客户 张三
John Doe, Jane Smith, Bob Wilson
亲爱的 张三，您的订单 ORD-2025-001 已发货，预计 2025-06-12 送达。
```

## 注意事项

1. **性能优先**：对大文本量操作时，预编译正则 `[regex]::new($pattern, 'Compiled')` 可以提升性能
2. **贪婪 vs 非贪婪**：默认贪婪匹配（`.*` 匹配尽可能多），使用 `.*?` 进行非贪婪匹配
3. **转义特殊字符**：使用 `[regex]::Escape($text)` 转义正则特殊字符，避免用户输入破坏正则
4. **多行模式**：处理多行文本时使用 `(?m)` 标志使 `^` 和 `$` 匹配行首行尾
5. **Unicode 支持**：PowerShell 正则支持 Unicode 类别，如 `\p{L}` 匹配任何语言的字母
6. **测试工具**：推荐使用 regex101.com 在线测试正则表达式，支持实时匹配和解释
