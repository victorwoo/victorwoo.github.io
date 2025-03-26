---
layout: post
date: 2025-01-13 08:00:00
title: "PowerShell 技能连载 - 正则表达式处理技巧"
description: PowerTip of the Day - PowerShell Regular Expression Tips
categories:
- powershell
- tip
tags:
- powershell
- tip
- powertip
- series
---
在 PowerShell 中，正则表达式（Regex）是一个强大的文本处理工具。本文将介绍一些实用的正则表达式技巧，帮助您更有效地处理文本数据。

首先，让我们看看基本的正则表达式匹配：

```powershell
# 基本匹配
$text = "我的邮箱是 example@domain.com，电话是 123-456-7890"
$emailPattern = "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
$phonePattern = "\d{3}-\d{3}-\d{4}"

# 提取邮箱
$email = [regex]::Match($text, $emailPattern).Value
Write-Host "邮箱地址：$email"

# 提取电话号码
$phone = [regex]::Match($text, $phonePattern).Value
Write-Host "电话号码：$phone"
```

使用正则表达式进行文本替换：

```powershell
# 替换敏感信息
$logContent = @"
用户登录信息：
用户名：admin
密码：123456
IP地址：192.168.1.100
"@

# 替换密码和IP地址
$maskedContent = $logContent -replace "密码：.*", "密码：******"
$maskedContent = $maskedContent -replace "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}", "***.***.***.***"

Write-Host "`n处理后的日志内容："
Write-Host $maskedContent
```

使用正则表达式验证数据格式：

```powershell
function Test-DataFormat {
    param(
        [string]$InputString,
        [string]$Pattern
    )
    
    if ($InputString -match $Pattern) {
        return $true
    }
    return $false
}

# 验证中文姓名（2-4个汉字）
$namePattern = "^[\u4e00-\u9fa5]{2,4}$"
$testNames = @("张三", "李四", "王小明", "赵", "John")

foreach ($name in $testNames) {
    $isValid = Test-DataFormat -InputString $name -Pattern $namePattern
    Write-Host "姓名 '$name' 是否有效：$isValid"
}
```

使用正则表达式提取结构化数据：

```powershell
# 解析日志文件
$logEntry = "2024-03-27 10:30:45 [ERROR] 用户登录失败 - IP: 192.168.1.100, 用户名: admin"
$logPattern = "(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(\w+)\] (.+) - IP: (\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}), 用户名: (\w+)"

$matches = [regex]::Match($logEntry, $logPattern)
if ($matches.Success) {
    $timestamp = $matches.Groups[1].Value
    $level = $matches.Groups[2].Value
    $message = $matches.Groups[3].Value
    $ip = $matches.Groups[4].Value
    $username = $matches.Groups[5].Value
    
    Write-Host "`n解析结果："
    Write-Host "时间：$timestamp"
    Write-Host "级别：$level"
    Write-Host "消息：$message"
    Write-Host "IP：$ip"
    Write-Host "用户名：$username"
}
```

一些实用的正则表达式技巧：

1. 使用命名捕获组：
```powershell
$pattern = "(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})"
$date = "2024-03-27"
$matches = [regex]::Match($date, $pattern)
Write-Host "年份：$($matches.Groups['year'].Value)"
```

2. 使用正向预查和负向预查：
```powershell
# 匹配后面跟着"元"的数字
$pricePattern = "\d+(?=元)"
$text = "商品价格：100元，运费：20元"
$prices = [regex]::Matches($text, $pricePattern) | ForEach-Object { $_.Value }
Write-Host "`n价格：$($prices -join ', ')"
```

3. 使用正则表达式进行文本清理：
```powershell
$dirtyText = "Hello   World!   This   has   extra   spaces."
$cleanText = $dirtyText -replace "\s+", " "
Write-Host "清理后的文本：$cleanText"
```

这些技巧将帮助您更有效地处理文本数据。记住，正则表达式虽然强大，但也要注意性能影响，特别是在处理大量数据时。对于简单的字符串操作，使用基本的字符串方法可能更高效。 